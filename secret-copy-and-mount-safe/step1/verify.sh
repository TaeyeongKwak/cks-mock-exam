#!/bin/bash
set -euo pipefail

USERNAME_FILE="/root/secret-lab/username.txt"
PASSWORD_FILE="/root/secret-lab/password.txt"

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get secret root-admin -n vault >/dev/null 2>&1 || fail "Secret root-admin not found in namespace vault"

[ -f "${USERNAME_FILE}" ] || fail "File not found: ${USERNAME_FILE}"
[ -f "${PASSWORD_FILE}" ] || fail "File not found: ${PASSWORD_FILE}"

expected_username="$(kubectl get secret root-admin -n vault -o jsonpath='{.data.username}' | base64 -d)"
expected_password="$(kubectl get secret root-admin -n vault -o jsonpath='{.data.password}' | base64 -d)"

actual_username="$(tr -d '\r\n' < "${USERNAME_FILE}")"
actual_password="$(tr -d '\r\n' < "${PASSWORD_FILE}")"

[ "${actual_username}" = "${expected_username}" ] || fail "username.txt does not match Secret root-admin.username"
[ "${actual_password}" = "${expected_password}" ] || fail "password.txt does not match Secret root-admin.password"

kubectl get secret app-secret -n vault >/dev/null 2>&1 || fail "Secret app-secret not found in namespace vault"

new_username="$(kubectl get secret app-secret -n vault -o jsonpath='{.data.username}' | base64 -d)"
new_password="$(kubectl get secret app-secret -n vault -o jsonpath='{.data.password}' | base64 -d)"
[ "${new_username}" = "dbadmin" ] || fail "Secret app-secret.username must be dbadmin"
[ "${new_password}" = "moresecurepas" ] || fail "Secret app-secret.password must be moresecurepas"

kubectl get pod secret-mount-pod -n vault >/dev/null 2>&1 || fail "Pod secret-mount-pod not found in namespace vault"
kubectl wait --for=condition=Ready pod/secret-mount-pod -n vault --timeout=180s >/dev/null 2>&1 || fail "Pod secret-mount-pod is not Ready"

pod_json="$(kubectl get pod secret-mount-pod -n vault -o json)"
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
        if vol and vol.get("secret", {}).get("secretName") == "app-secret":
            mounted = True
            break
if not mounted:
    print("Pod secret-mount-pod must mount Secret app-secret", file=sys.stderr)
    sys.exit(1)
PY

echo "Verification passed"
