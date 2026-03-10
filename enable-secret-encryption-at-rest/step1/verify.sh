#!/bin/bash
set -euo pipefail

MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"
ENC_CONFIG="/etc/kubernetes/pki/encryption-config.yaml"
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
[ -f "${ENC_CONFIG}" ] || fail "Encryption config file not found at ${ENC_CONFIG}"

grep -q -- '--encryption-provider-config=/etc/kubernetes/pki/encryption-config.yaml' "${MANIFEST}" || fail "kube-apiserver must use --encryption-provider-config=/etc/kubernetes/pki/encryption-config.yaml"

apiserver_id="$(crictl ps --name kube-apiserver -q | head -n 1 | tr -d '\r')"
[ -n "${apiserver_id}" ] || fail "Running kube-apiserver container not found"
apiserver_inspect="$(crictl inspect "${apiserver_id}" 2>/dev/null || true)"
echo "${apiserver_inspect}" | grep -q -- '--encryption-provider-config=/etc/kubernetes/pki/encryption-config.yaml' || fail "Running kube-apiserver is not using the encryption config"

ENC_FILE="$(cat "${ENC_CONFIG}")" python3 - <<'PY' || exit 1
import os
import re
import sys

text = os.environ["ENC_FILE"]
if "kind: EncryptionConfiguration" not in text:
    print("Encryption config kind must be EncryptionConfiguration", file=sys.stderr)
    sys.exit(1)
if "resources:" not in text:
    print("Encryption config must define resources", file=sys.stderr)
    sys.exit(1)
if "secrets" not in text:
    print("Encryption config must target secrets", file=sys.stderr)
    sys.exit(1)

aescbc_match = re.search(r'(?m)^([ \t]*)- +aescbc:\s*$', text)
identity_match = re.search(r'(?m)^([ \t]*)- +identity:\s*\{\s*\}\s*$', text)
if not aescbc_match:
    print("Encryption config must include an aescbc provider", file=sys.stderr)
    sys.exit(1)
if not identity_match:
    print("Encryption config must include an identity provider", file=sys.stderr)
    sys.exit(1)
if aescbc_match.start() > identity_match.start():
    print("aescbc must appear before identity", file=sys.stderr)
    sys.exit(1)
if not re.search(r'(?ms)- +aescbc:\s*\n(?:^[ \t].*\n)*?^[ \t]*keys:\s*\n(?:^[ \t].*\n)*?^[ \t]*- +name:\s*\S+\s*\n(?:^[ \t].*\n)*?^[ \t]*secret:\s*[A-Za-z0-9+/=]{44}\s*$', text):
    print("aescbc provider must include a 32-byte base64 key", file=sys.stderr)
    sys.exit(1)
PY

kubectl --kubeconfig="${KUBECONFIG}" get secret app-secret -n default >/dev/null 2>&1 || fail "Secret app-secret not found in default namespace"

etcd_id="$(crictl ps --name etcd -q | head -n 1 | tr -d '\r')"
[ -n "${etcd_id}" ] || fail "Running etcd container not found"

etcd_json="$(
  crictl exec "${etcd_id}" \
    etcdctl \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
    --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
    get /registry/secrets/default/app-secret -w json \
    2>/dev/null || true
)"
[ -n "${etcd_json}" ] || fail "Unable to read app-secret directly from etcd"

ETCD_JSON="${etcd_json}" python3 - <<'PY' || exit 1
import base64
import json
import os
import sys

data = json.loads(os.environ["ETCD_JSON"])
kvs = data.get("kvs") or []
if not kvs:
    print("Secret app-secret was not found in etcd", file=sys.stderr)
    sys.exit(1)
raw = base64.b64decode(kvs[0]["value"])
if not raw.startswith(b"k8s:enc:aescbc:v1:"):
    print("Secret app-secret is not encrypted with aescbc in etcd", file=sys.stderr)
    sys.exit(1)
if b"verysecretvalue" in raw:
    print("Secret app-secret still appears to be stored in plaintext", file=sys.stderr)
    sys.exit(1)
PY

kubectl --kubeconfig="${KUBECONFIG}" get nodes >/dev/null 2>&1 || fail "Authenticated kubectl access failed"

echo "Verification passed"
