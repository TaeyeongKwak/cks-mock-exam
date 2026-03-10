#!/bin/bash
set -euo pipefail

CA_FILE="/root/cluster-ca.crt"

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get secret default-token-alpha -n dev-sec >/dev/null 2>&1 || fail "Secret default-token-alpha not found in namespace dev-sec"

[ -f "${CA_FILE}" ] || fail "File not found: ${CA_FILE}"
expected_ca="$(kubectl get secret default-token-alpha -n dev-sec -o jsonpath='{.data.ca\.crt}' | base64 -d)"
actual_ca="$(cat "${CA_FILE}")"
[ "${actual_ca}" = "${expected_ca}" ] || fail "File ${CA_FILE} does not match Secret default-token-alpha ca.crt data"

kubectl get secret web-config-secret -n portal >/dev/null 2>&1 || fail "Secret web-config-secret not found in namespace portal"
app_user="$(kubectl get secret web-config-secret -n portal -o jsonpath='{.data.APP_USER}' | base64 -d)"
app_pass="$(kubectl get secret web-config-secret -n portal -o jsonpath='{.data.APP_PASS}' | base64 -d)"
[ "${app_user}" = "appadmin" ] || fail "Secret web-config-secret APP_USER must be appadmin"
[ "${app_pass}" = "Sup3rS3cret" ] || fail "Secret web-config-secret APP_PASS must be Sup3rS3cret"

kubectl get pod web-config-pod -n portal >/dev/null 2>&1 || fail "Pod web-config-pod not found in namespace portal"
kubectl wait --for=condition=Ready pod/web-config-pod -n portal --timeout=180s >/dev/null 2>&1 || fail "Pod web-config-pod is not Ready"

image_name="$(kubectl get pod web-config-pod -n portal -o jsonpath='{.spec.containers[0].image}')"
case "${image_name}" in
  nginx|nginx:*) ;;
  *) fail "Pod web-config-pod must use an nginx image" ;;
esac

pod_json="$(kubectl get pod web-config-pod -n portal -o json)"
POD_JSON="${pod_json}" python3 - <<'PY' || exit 1
import json
import os
import sys

data = json.loads(os.environ["POD_JSON"])
volumes = {v.get("name"): v for v in data.get("spec", {}).get("volumes", [])}
mounted = False
for container in data.get("spec", {}).get("containers", []):
    for mount in container.get("volumeMounts", []) or []:
        vol = volumes.get(mount.get("name"))
        if mount.get("mountPath") == "/etc/app-config" and vol and vol.get("secret", {}).get("secretName") == "web-config-secret":
            mounted = True
            break
if not mounted:
    print("Pod web-config-pod must mount Secret web-config-secret at /etc/app-config", file=sys.stderr)
    sys.exit(1)
PY

mounted_user="$(kubectl exec -n portal web-config-pod -- cat /etc/app-config/APP_USER 2>/dev/null || true)"
mounted_pass="$(kubectl exec -n portal web-config-pod -- cat /etc/app-config/APP_PASS 2>/dev/null || true)"
[ "${mounted_user}" = "appadmin" ] || fail "Mounted file /etc/app-config/APP_USER must contain appadmin"
[ "${mounted_pass}" = "Sup3rS3cret" ] || fail "Mounted file /etc/app-config/APP_PASS must contain Sup3rS3cret"

echo "Verification passed"
