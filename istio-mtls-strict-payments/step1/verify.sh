#!/bin/bash
set -euo pipefail

KUBECONFIG="/etc/kubernetes/admin.conf"
PEERAUTH_FILE="/root/billing-peerauth.yaml"

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get namespace billing >/dev/null 2>&1 || fail "Namespace billing not found"

inject_label="$(kubectl get namespace billing -o jsonpath='{.metadata.labels.istio-injection}')"
[ "${inject_label}" = "enabled" ] || fail "Namespace billing must have istio-injection=enabled"

[ -f "${PEERAUTH_FILE}" ] || fail "PeerAuthentication manifest not found at /root/billing-peerauth.yaml"
kubectl create --dry-run=client -f "${PEERAUTH_FILE}" >/dev/null 2>&1 || fail "PeerAuthentication manifest is not valid"

file_kind="$(kubectl create --dry-run=client -f "${PEERAUTH_FILE}" -o jsonpath='{.kind}' 2>/dev/null)"
[ "${file_kind}" = "PeerAuthentication" ] || fail "payments-peerauth.yaml must define a PeerAuthentication resource"

file_ns="$(kubectl create --dry-run=client -f "${PEERAUTH_FILE}" -o jsonpath='{.metadata.namespace}' 2>/dev/null)"
[ "${file_ns}" = "billing" ] || fail "PeerAuthentication must target namespace billing"

file_mode="$(kubectl create --dry-run=client -f "${PEERAUTH_FILE}" -o jsonpath='{.spec.mtls.mode}' 2>/dev/null)"
[ "${file_mode}" = "STRICT" ] || fail "PeerAuthentication must set spec.mtls.mode to STRICT"

FILE_JSON="$(kubectl create --dry-run=client -f "${PEERAUTH_FILE}" -o json 2>/dev/null)" python3 - <<'PY' || exit 1
import json
import os
import sys

data = json.loads(os.environ["FILE_JSON"])
selector = data.get("spec", {}).get("selector")
if selector:
    print("PeerAuthentication must be namespace-wide and should not use a selector", file=sys.stderr)
    sys.exit(1)
PY

live_name="$(
  PEERAUTH_JSON="$(kubectl get peerauthentication -n billing -o json 2>/dev/null || true)" python3 - <<'PY'
import json
import os
import sys

raw = os.environ.get("PEERAUTH_JSON", "")
if not raw:
    sys.exit(0)

data = json.loads(raw)
for item in data.get("items", []):
    spec = item.get("spec", {})
    if spec.get("mtls", {}).get("mode") == "STRICT" and not spec.get("selector"):
        print(item["metadata"]["name"])
        break
PY
)"
[ -n "${live_name}" ] || fail "No namespace-wide PeerAuthentication with STRICT mode found in billing"

for deploy in httpbin curl; do
  kubectl rollout status "deployment/${deploy}" -n billing --timeout=180s >/dev/null 2>&1 || fail "Deployment ${deploy} is not ready"
done

for pod in "$(kubectl get pods -n billing -l app=httpbin -o jsonpath='{.items[0].metadata.name}')" "$(kubectl get pods -n billing -l app=curl -o jsonpath='{.items[0].metadata.name}')"; do
  [ -n "${pod}" ] || fail "Expected Pod not found in billing"
  pod_json="$(kubectl get pod "${pod}" -n billing -o json 2>/dev/null || true)"
  POD_JSON="${pod_json}" python3 - <<'PY' || exit 1
import json
import os
import sys

data = json.loads(os.environ["POD_JSON"])

containers = [c.get("name") for c in data.get("spec", {}).get("containers", [])]
init_containers = [c.get("name") for c in data.get("spec", {}).get("initContainers", [])]
annotations = data.get("metadata", {}).get("annotations", {})
status = annotations.get("sidecar.istio.io/status", "")

if "istio-proxy" in containers or "istio-proxy" in init_containers or "istio-proxy" in status:
    sys.exit(0)

print(f"Pod {data.get('metadata', {}).get('name')} does not have an injected istio-proxy sidecar", file=sys.stderr)
sys.exit(1)
PY
done

curl_pod="$(kubectl get pods -n billing -l app=curl -o jsonpath='{.items[0].metadata.name}')"
[ -n "${curl_pod}" ] || fail "curl Pod not found in billing"

headers="$(
  kubectl exec -n billing "${curl_pod}" -c curl -- \
    curl -fsS http://httpbin.billing:8000/headers 2>/dev/null || true
)"
[ -n "${headers}" ] || fail "curl Pod could not reach httpbin after STRICT mTLS enforcement"

HEADERS_JSON="${headers}" python3 - <<'PY' || exit 1
import json
import os
import sys

data = json.loads(os.environ["HEADERS_JSON"])
headers = data.get("headers", {})
xfcc = headers.get("X-Forwarded-Client-Cert")
if not xfcc:
    print("X-Forwarded-Client-Cert header not found; mTLS was not confirmed", file=sys.stderr)
    sys.exit(1)
if isinstance(xfcc, list):
    value = xfcc[0]
else:
    value = xfcc
if "spiffe://" not in value:
    print("X-Forwarded-Client-Cert header does not show Istio identity information", file=sys.stderr)
    sys.exit(1)
PY

echo "Verification passed"
