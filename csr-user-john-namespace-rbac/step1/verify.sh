#!/bin/bash
set -euo pipefail

WORKDIR="/srv/cert-lab"

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get namespace tenant-user >/dev/null 2>&1 || fail "Namespace tenant-user not found"
kubectl get csr marie-access >/dev/null 2>&1 || fail "CSR marie-access not found"

csr_json="$(kubectl get csr marie-access -o json)"
CSR_JSON="${csr_json}" python3 - <<'PY' || exit 1
import json
import os
import sys

data = json.loads(os.environ["CSR_JSON"])
conditions = data.get("status", {}).get("conditions", [])
if not any(c.get("type") == "Approved" for c in conditions):
    print("CSR marie-access is not approved", file=sys.stderr)
    sys.exit(1)
if not data.get("status", {}).get("certificate"):
    print("CSR marie-access does not contain a signed certificate", file=sys.stderr)
    sys.exit(1)
if data.get("spec", {}).get("signerName") != "kubernetes.io/kube-apiserver-client":
    print("CSR marie-access must use signer kubernetes.io/kube-apiserver-client", file=sys.stderr)
    sys.exit(1)
PY

[ -f "${WORKDIR}/marie.key" ] || fail "Private key not found at ${WORKDIR}/marie.key"
[ -f "${WORKDIR}/marie.crt" ] || fail "Signed certificate not found at ${WORKDIR}/marie.crt"
[ -s "${WORKDIR}/marie.crt" ] || fail "Signed certificate file is empty"

openssl x509 -in "${WORKDIR}/marie.crt" -noout -subject 2>/dev/null | grep -q 'CN = marie' || fail "Signed certificate subject must be CN=marie"

kubectl get role tenant-editor -n tenant-user >/dev/null 2>&1 || fail "Role tenant-editor not found in tenant-user"
kubectl get rolebinding tenant-editor-bind -n tenant-user >/dev/null 2>&1 || fail "RoleBinding tenant-editor-bind not found in tenant-user"

role_json="$(kubectl get role tenant-editor -n tenant-user -o json)"
ROLE_JSON="${role_json}" python3 - <<'PY' || exit 1
import json
import os
import sys

data = json.loads(os.environ["ROLE_JSON"])
rules = data.get("rules", [])
required_verbs = {"list", "get", "create", "delete"}
ok = False
for rule in rules:
    if set(rule.get("resources", [])) == {"pods", "secrets"} and required_verbs.issubset(set(rule.get("verbs", []))) and rule.get("apiGroups", []) == [""]:
        ok = True
        break
if not ok:
    print("Role tenant-editor must allow list/get/create/delete on pods and secrets in the core API group", file=sys.stderr)
    sys.exit(1)
PY

binding_json="$(kubectl get rolebinding tenant-editor-bind -n tenant-user -o json)"
BINDING_JSON="${binding_json}" python3 - <<'PY' || exit 1
import json
import os
import sys

data = json.loads(os.environ["BINDING_JSON"])
role_ref = data.get("roleRef", {})
if role_ref.get("kind") != "Role" or role_ref.get("name") != "tenant-editor":
    print("RoleBinding tenant-editor-bind must reference Role tenant-editor", file=sys.stderr)
    sys.exit(1)
if not any(s.get("kind") == "User" and s.get("name") == "marie" for s in data.get("subjects", [])):
    print("RoleBinding tenant-editor-bind must bind to user marie", file=sys.stderr)
    sys.exit(1)
PY

if [ -f "${WORKDIR}/marie.kubeconfig" ]; then
  for verb in get list create delete; do
    kubectl --kubeconfig="${WORKDIR}/marie.kubeconfig" auth can-i "${verb}" pods -n tenant-user >/dev/null 2>&1 || fail "marie.kubeconfig cannot ${verb} pods in namespace tenant-user"
    kubectl --kubeconfig="${WORKDIR}/marie.kubeconfig" auth can-i "${verb}" secrets -n tenant-user >/dev/null 2>&1 || fail "marie.kubeconfig cannot ${verb} secrets in namespace tenant-user"
  done
else
  cani_output="$(kubectl auth can-i --as=marie create secrets -n tenant-user 2>/dev/null || true)"
  [ "${cani_output}" = "yes" ] || fail "User marie does not have the expected RBAC permissions"
fi

echo "Verification passed"
