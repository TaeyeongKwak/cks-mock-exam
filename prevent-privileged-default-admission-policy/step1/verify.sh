#!/bin/bash
set -euo pipefail

PRIV_MANIFEST="/root/policy-lab/privileged-pod.yaml"
SAFE_MANIFEST="/root/policy-lab/non-privileged-pod.yaml"

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get serviceaccount psp-sa -n policy-lab >/dev/null 2>&1 || fail "ServiceAccount psp-sa not found in policy-lab"
[ -f "${PRIV_MANIFEST}" ] || fail "Manifest not found at ${PRIV_MANIFEST}"
[ -f "${SAFE_MANIFEST}" ] || fail "Manifest not found at ${SAFE_MANIFEST}"

kubectl get clusterrole prevent-role >/dev/null 2>&1 || fail "ClusterRole prevent-role not found"
kubectl get clusterrolebinding prevent-role-binding >/dev/null 2>&1 || fail "ClusterRoleBinding prevent-role-binding not found"
kubectl get validatingadmissionpolicy prevent-privileged-policy >/dev/null 2>&1 || fail "ValidatingAdmissionPolicy prevent-privileged-policy not found"
kubectl get validatingadmissionpolicybinding prevent-privileged-binding >/dev/null 2>&1 || fail "ValidatingAdmissionPolicyBinding prevent-privileged-binding not found"

role_json="$(kubectl get clusterrole prevent-role -o json)"
ROLE_JSON="${role_json}" python3 - <<'PY' || exit 1
import json
import os
import sys

data = json.loads(os.environ["ROLE_JSON"])
rules = data.get("rules", [])
if len(rules) != 1:
    print("ClusterRole prevent-role must contain exactly one rule", file=sys.stderr)
    sys.exit(1)
rule = rules[0]
if sorted(rule.get("apiGroups", [])) not in ([], [""]):
    print("ClusterRole prevent-role must target the core API group", file=sys.stderr)
    sys.exit(1)
if sorted(rule.get("resources", [])) != ["pods"]:
    print("ClusterRole prevent-role must allow only pods", file=sys.stderr)
    sys.exit(1)
if sorted(rule.get("verbs", [])) != ["create"]:
    print("ClusterRole prevent-role must allow only create", file=sys.stderr)
    sys.exit(1)
if any(key in rule for key in ("resourceNames", "nonResourceURLs")):
    print("ClusterRole prevent-role must not restrict resourceNames or nonResourceURLs", file=sys.stderr)
    sys.exit(1)
PY

binding_ref="$(kubectl get clusterrolebinding prevent-role-binding -o jsonpath='{.roleRef.kind}:{.roleRef.name}')"
[ "${binding_ref}" = "ClusterRole:prevent-role" ] || fail "ClusterRoleBinding prevent-role-binding must reference ClusterRole prevent-role"

binding_subject="$(kubectl get clusterrolebinding prevent-role-binding -o jsonpath='{.subjects[0].kind}:{.subjects[0].name}:{.subjects[0].namespace}')"
[ "${binding_subject}" = "ServiceAccount:psp-sa:policy-lab" ] || fail "ClusterRoleBinding prevent-role-binding must bind ServiceAccount psp-sa in policy-lab"

policy_json="$(kubectl get validatingadmissionpolicy prevent-privileged-policy -o json)"
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
if "privileged" not in expr:
    print("ValidatingAdmissionPolicy validation must check for privileged containers", file=sys.stderr)
    sys.exit(1)
PY

binding_json="$(kubectl get validatingadmissionpolicybinding prevent-privileged-binding -o json)"
BINDING_JSON="${binding_json}" python3 - <<'PY' || exit 1
import json
import os
import sys

data = json.loads(os.environ["BINDING_JSON"])
spec = data.get("spec", {})
if spec.get("policyName") != "prevent-privileged-policy":
    print("ValidatingAdmissionPolicyBinding must reference prevent-privileged-policy", file=sys.stderr)
    sys.exit(1)

actions = spec.get("validationActions", [])
if actions != ["Deny"]:
    print("ValidatingAdmissionPolicyBinding must use validationActions: [Deny]", file=sys.stderr)
    sys.exit(1)

selector = spec.get("matchResources", {}).get("namespaceSelector", {}).get("matchLabels", {})
if selector.get("kubernetes.io/metadata.name") != "policy-lab":
    print("ValidatingAdmissionPolicyBinding must target namespace policy-lab", file=sys.stderr)
    sys.exit(1)
PY

can_create="$(kubectl auth can-i create pods -n policy-lab --as=system:serviceaccount:policy-lab:psp-sa)"
[ "${can_create}" = "yes" ] || fail "ServiceAccount psp-sa must be allowed to create pods in policy-lab"

if ! kubectl apply --dry-run=server --as=system:serviceaccount:policy-lab:psp-sa -f "${SAFE_MANIFEST}" >/dev/null 2>&1; then
  fail "Non-privileged Pod manifest should be accepted for psp-sa with server dry-run"
fi

set +e
priv_output="$(kubectl apply --dry-run=server --as=system:serviceaccount:policy-lab:psp-sa -f "${PRIV_MANIFEST}" 2>&1)"
priv_status=$?
set -e
[ "${priv_status}" -ne 0 ] || fail "Privileged Pod manifest should be rejected by admission policy"
echo "${priv_output}" | grep -Eiq 'prevent-privileged-policy|privileged|denied|forbidden' || fail "Privileged Pod rejection output should mention admission denial"

echo "Verification passed"
