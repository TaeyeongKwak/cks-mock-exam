#!/bin/bash
set -euo pipefail

APISERVER="/etc/kubernetes/manifests/kube-apiserver.yaml"
ETCD="/etc/kubernetes/manifests/etcd.yaml"
KUBELET_CONFIG="/var/lib/kubelet/config.yaml"
KUBECONFIG="/etc/kubernetes/admin.conf"

fail() {
  echo "$1" >&2
  exit 1
}

wait_api() {
  for _ in $(seq 1 90); do
    if kubectl --kubeconfig="${KUBECONFIG}" get --raw /readyz >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  return 1
}

wait_api || fail "API server is not ready"

grep -q -- '--kubelet-certificate-authority=/etc/kubernetes/pki/ca.crt' "${APISERVER}" || fail "kube-apiserver must use --kubelet-certificate-authority=/etc/kubernetes/pki/ca.crt"

disable_line="$(grep -- '--disable-admission-plugins=' "${APISERVER}" || true)"
echo "${disable_line}" | grep -q 'PodSecurity' && fail "PodSecurity admission plugin must not be disabled"

apiserver_id="$(crictl ps --name kube-apiserver -q | head -n 1 | tr -d '\r')"
[ -n "${apiserver_id}" ] || fail "Running kube-apiserver container not found"
apiserver_inspect="$(crictl inspect "${apiserver_id}" 2>/dev/null || true)"
echo "${apiserver_inspect}" | grep -q -- '--kubelet-certificate-authority=/etc/kubernetes/pki/ca.crt' || fail "Running kube-apiserver is not using the required kubelet CA"
echo "${apiserver_inspect}" | grep -q -- '--disable-admission-plugins=' && echo "${apiserver_inspect}" | grep -q 'PodSecurity' && fail "Running kube-apiserver still disables PodSecurity"

KUBELET_FILE="$(cat "${KUBELET_CONFIG}")" python3 - <<'PY' || exit 1
import os
import re
import sys

text = os.environ["KUBELET_FILE"]
if not re.search(r'(?m)^[ \t]*serverTLSBootstrap:[ \t]*true[ \t]*$', text):
    print("kubelet config must set serverTLSBootstrap: true", file=sys.stderr)
    sys.exit(1)
if not re.search(r'(?ms)^authentication:\n(?:^[ \t].*\n)*?^[ \t]*anonymous:\n(?:^[ \t].*\n)*?^[ \t]*enabled:[ \t]*false[ \t]*$', text):
    print("kubelet config must disable anonymous authentication", file=sys.stderr)
    sys.exit(1)
if not re.search(r'(?ms)^authorization:\n(?:^[ \t].*\n)*?^[ \t]*mode:[ \t]*Webhook[ \t]*$', text):
    print("kubelet config must set authorization.mode to Webhook", file=sys.stderr)
    sys.exit(1)
PY

configz="$(kubectl --kubeconfig="${KUBECONFIG}" get --raw '/api/v1/nodes/controlplane/proxy/configz' 2>/dev/null || true)"
[ -n "${configz}" ] || fail "Unable to read live kubelet configz from controlplane"
CONFIGZ="${configz}" python3 - <<'PY' || exit 1
import json
import os
import sys

data = json.loads(os.environ["CONFIGZ"])
cfg = data.get("kubeletconfig", {})
if cfg.get("serverTLSBootstrap") is not True:
    print("Live kubelet config does not have serverTLSBootstrap=true", file=sys.stderr)
    sys.exit(1)
if cfg.get("authentication", {}).get("anonymous", {}).get("enabled") is not False:
    print("Live kubelet config does not disable anonymous authentication", file=sys.stderr)
    sys.exit(1)
if cfg.get("authorization", {}).get("mode") != "Webhook":
    print("Live kubelet config does not use Webhook authorization", file=sys.stderr)
    sys.exit(1)
PY

grep -q -- '--auto-tls=true' "${ETCD}" && fail "etcd must not use --auto-tls=true"
grep -q -- '--peer-auto-tls=true' "${ETCD}" && fail "etcd must not use --peer-auto-tls=true"

etcd_id="$(crictl ps --name etcd -q | head -n 1 | tr -d '\r')"
[ -n "${etcd_id}" ] || fail "Running etcd container not found"
etcd_inspect="$(crictl inspect "${etcd_id}" 2>/dev/null || true)"
echo "${etcd_inspect}" | grep -q -- '--auto-tls=true' && fail "Running etcd still uses --auto-tls=true"
echo "${etcd_inspect}" | grep -q -- '--peer-auto-tls=true' && fail "Running etcd still uses --peer-auto-tls=true"

kubectl --kubeconfig="${KUBECONFIG}" get nodes >/dev/null 2>&1 || fail "Authenticated kubectl access failed"

echo "Verification passed"
