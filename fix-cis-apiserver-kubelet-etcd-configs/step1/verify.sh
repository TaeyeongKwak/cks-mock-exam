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

auth_line="$(grep -- '--authorization-mode=' "${APISERVER}" || true)"
echo "${auth_line}" | grep -q 'Node' || fail "kube-apiserver authorization-mode must include Node"
echo "${auth_line}" | grep -q 'RBAC' || fail "kube-apiserver authorization-mode must include RBAC"
echo "${auth_line}" | grep -q 'AlwaysAllow' && fail "kube-apiserver authorization-mode must not use AlwaysAllow"

apiserver_id="$(crictl ps --name kube-apiserver -q | head -n 1 | tr -d '\r')"
[ -n "${apiserver_id}" ] || fail "Running kube-apiserver container not found"
apiserver_inspect="$(crictl inspect "${apiserver_id}" 2>/dev/null || true)"
echo "${apiserver_inspect}" | grep -q 'authorization-mode=.*Node' || fail "Running kube-apiserver does not include Node authorization"
echo "${apiserver_inspect}" | grep -q 'authorization-mode=.*RBAC' || fail "Running kube-apiserver does not include RBAC authorization"
echo "${apiserver_inspect}" | grep -q 'authorization-mode=.*AlwaysAllow' && fail "Running kube-apiserver still uses AlwaysAllow"

KUBELET_FILE="$(cat "${KUBELET_CONFIG}")" python3 - <<'PY' || exit 1
import os
import re
import sys

text = os.environ["KUBELET_FILE"]
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
if cfg.get("authentication", {}).get("anonymous", {}).get("enabled") is not False:
    print("Live kubelet config does not disable anonymous authentication", file=sys.stderr)
    sys.exit(1)
if cfg.get("authorization", {}).get("mode") != "Webhook":
    print("Live kubelet config does not use Webhook authorization", file=sys.stderr)
    sys.exit(1)
PY

grep -q -- '--client-cert-auth=true' "${ETCD}" || fail "etcd must set --client-cert-auth=true"
grep -q -- '--auto-tls=true' "${ETCD}" && fail "etcd must not use --auto-tls=true"
grep -q -- '--cert-file=/etc/kubernetes/pki/etcd/server.crt' "${ETCD}" || fail "etcd must use the kubeadm server certificate"
grep -q -- '--key-file=/etc/kubernetes/pki/etcd/server.key' "${ETCD}" || fail "etcd must use the kubeadm server key"
grep -q -- '--trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt' "${ETCD}" || fail "etcd must use the kubeadm trusted CA file"

etcd_id="$(crictl ps --name etcd -q | head -n 1 | tr -d '\r')"
[ -n "${etcd_id}" ] || fail "Running etcd container not found"
etcd_inspect="$(crictl inspect "${etcd_id}" 2>/dev/null || true)"
echo "${etcd_inspect}" | grep -q -- '--client-cert-auth=true' || fail "Running etcd does not enable client-cert-auth"
echo "${etcd_inspect}" | grep -q -- '--auto-tls=true' && fail "Running etcd still uses auto-tls"
echo "${etcd_inspect}" | grep -q -- '--trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt' || fail "Running etcd does not use the kubeadm CA file"

issuer="$(openssl x509 -in /etc/kubernetes/pki/etcd/server.crt -noout -issuer 2>/dev/null || true)"
subject="$(openssl x509 -in /etc/kubernetes/pki/etcd/server.crt -noout -subject 2>/dev/null || true)"
[ -n "${issuer}" ] || fail "Could not read etcd server certificate issuer"
[ -n "${subject}" ] || fail "Could not read etcd server certificate subject"
[ "${issuer}" != "${subject}" ] || fail "etcd server certificate appears to be self-signed"

kubectl --kubeconfig="${KUBECONFIG}" get nodes >/dev/null 2>&1 || fail "Authenticated kubectl access failed"

echo "Verification passed"
