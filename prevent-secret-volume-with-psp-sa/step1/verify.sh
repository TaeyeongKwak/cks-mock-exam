#!/bin/bash
set -euo pipefail

SECRET_MANIFEST="/root/policy-zone/secret-volume-pod.yaml"
PVC_MANIFEST="/root/policy-zone/pvc-volume-pod.yaml"

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get namespace policy-zone >/dev/null 2>&1 || fail "Namespace policy-zone not found"
kubectl get serviceaccount psp-sa -n policy-zone >/dev/null 2>&1 || fail "ServiceAccount psp-sa not found in policy-zone"
kubectl get clusterrole psp-role >/dev/null 2>&1 || fail "ClusterRole psp-role not found"
kubectl get clusterrolebinding psp-role-binding >/dev/null 2>&1 || fail "ClusterRoleBinding psp-role-binding not found"
kubectl get validatingadmissionpolicy prevent-volume-policy >/dev/null 2>&1 || fail "ValidatingAdmissionPolicy prevent-volume-policy not found"
kubectl get validatingadmissionpolicybinding prevent-volume-policy-binding >/dev/null 2>&1 || fail "ValidatingAdmissionPolicyBinding prevent-volume-policy-binding not found"
[ -f "${SECRET_MANIFEST}" ] || fail "Manifest not found at ${SECRET_MANIFEST}"
[ -f "${PVC_MANIFEST}" ] || fail "Manifest not found at ${PVC_MANIFEST}"

role_json="$(kubectl get clusterrole psp-role -o json)"
ROLE_JSON="${role_json}" python3 - <<'PY' || exit 1
import json
import os
import sys

data = json.loads(os.environ["ROLE_JSON"])
rules = data.get("rules", [])
if len(rules) != 1:
    print("ClusterRole psp-role must contain exactly one rule", file=sys.stderr)
    sys.exit(1)
rule = rules[0]
if sorted(rule.get("apiGroups", [])) not in ([], [""]):
    print("ClusterRole psp-role must target the core API group", file=sys.stderr)
    sys.exit(1)
if sorted(rule.get("resources", [])) != ["pods"]:
    print("ClusterRole psp-role must allow only pods", file=sys.stderr)
    sys.exit(1)
if sorted(rule.get("verbs", [])) != ["create"]:
    print("ClusterRole psp-role must allow only create", file=sys.stderr)
    sys.exit(1)
PY

binding_ref="$(kubectl get clusterrolebinding psp-role-binding -o jsonpath='{.roleRef.kind}:{.roleRef.name}')"
[ "${binding_ref}" = "ClusterRole:psp-role" ] || fail "ClusterRoleBinding psp-role-binding must reference ClusterRole psp-role"

binding_subject="$(kubectl get clusterrolebinding psp-role-binding -o jsonpath='{.subjects[0].kind}:{.subjects[0].name}:{.subjects[0].namespace}')"
[ "${binding_subject}" = "ServiceAccount:psp-sa:policy-zone" ] || fail "ClusterRoleBinding psp-role-binding must bind ServiceAccount psp-sa in policy-zone"

policy_json="$(kubectl get validatingadmissionpolicy prevent-volume-policy -o json)"
POLICY_JSON="${policy_json}" python3 - <<'PY' || exit 1
import json
import os
import sys

data = json.loads(os.environ["POLICY_JSON"])
spec = data.get("spec", {})
rules = spec.get("matchConstraints", {}).get("resourceRules", [])
if not rules:
    print("ValidatingAdmissionPolicy must define resourceRules", file=sys.stderr)
    sys.exit(1)

matches_pods_create = False
for rule in rules:
    resources = set(rule.get("resources", []))
    operations = set(rule.get("operations", []))
    api_groups = set(rule.get("apiGroups", []))
    if "pods" in resources and "CREATE" in operations and api_groups in (set(), {""}):
        matches_pods_create = True
        break

if not matches_pods_create:
    print("ValidatingAdmissionPolicy must match CREATE on pods in the core API group", file=sys.stderr)
    sys.exit(1)

validations = spec.get("validations", [])
if not validations:
    print("ValidatingAdmissionPolicy must define at least one validation", file=sys.stderr)
    sys.exit(1)
expr = " ".join(v.get("expression", "") for v in validations)
if "persistentVolumeClaim" not in expr:
    print("ValidatingAdmissionPolicy validation must restrict volumes to persistentVolumeClaim", file=sys.stderr)
    sys.exit(1)
PY

binding_json="$(kubectl get validatingadmissionpolicybinding prevent-volume-policy-binding -o json)"
BINDING_JSON="${binding_json}" python3 - <<'PY' || exit 1
import json
import os
import sys

data = json.loads(os.environ["BINDING_JSON"])
spec = data.get("spec", {})
if spec.get("policyName") != "prevent-volume-policy":
    print("ValidatingAdmissionPolicyBinding must reference prevent-volume-policy", file=sys.stderr)
    sys.exit(1)

actions = spec.get("validationActions", [])
if actions != ["Deny"]:
    print("ValidatingAdmissionPolicyBinding must use validationActions: [Deny]", file=sys.stderr)
    sys.exit(1)

selector = spec.get("matchResources", {}).get("namespaceSelector", {}).get("matchLabels", {})
if selector.get("volume-policy") != "policy-zone":
    print("ValidatingAdmissionPolicyBinding must target namespace policy-zone", file=sys.stderr)
    sys.exit(1)
PY

can_create="$(kubectl auth can-i create pods -n policy-zone --as=system:serviceaccount:policy-zone:psp-sa)"
[ "${can_create}" = "yes" ] || fail "ServiceAccount psp-sa must be allowed to create pods in policy-zone"

if ! kubectl apply --dry-run=server --as=system:serviceaccount:policy-zone:psp-sa -f "${PVC_MANIFEST}" >/dev/null 2>&1; then
  fail "PVC-volume Pod manifest should be accepted for psp-sa with server dry-run"
fi

set +e
secret_output="$(kubectl apply --dry-run=server --as=system:serviceaccount:policy-zone:psp-sa -f "${SECRET_MANIFEST}" 2>&1)"
secret_status=$?
set -e
[ "${secret_status}" -ne 0 ] || fail "Secret-volume Pod manifest should be rejected by admission policy"
echo "${secret_output}" | grep -Eiq 'prevent-volume-policy|persistentVolumeClaim|volume|denied|forbidden' || fail "Secret-volume rejection output should mention admission denial"

echo "Verification passed"
