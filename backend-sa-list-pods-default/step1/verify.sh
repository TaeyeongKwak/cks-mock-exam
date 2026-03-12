#!/bin/bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get serviceaccount viewer-sa -n default >/dev/null 2>&1 || fail "ServiceAccount viewer-sa not found in default"
kubectl get role pod-viewer -n default >/dev/null 2>&1 || fail "Role pod-viewer not found in default"
kubectl get rolebinding pod-viewer-bind -n default >/dev/null 2>&1 || fail "RoleBinding pod-viewer-bind not found in default"
kubectl get pod inventory-shell -n default >/dev/null 2>&1 || fail "Pod inventory-shell not found in default"
kubectl wait --for=condition=Ready pod/inventory-shell -n default --timeout=120s >/dev/null 2>&1 || fail "Pod inventory-shell is not Ready"

pod_sa="$(kubectl get pod inventory-shell -n default -o jsonpath='{.spec.serviceAccountName}')"
[ "${pod_sa}" = "viewer-sa" ] || fail "Pod inventory-shell must use ServiceAccount viewer-sa"

role_json="$(kubectl get role pod-viewer -n default -o json)"
ROLE_JSON="${role_json}" python3 - <<'PY' || exit 1
import json
import os
import sys

data = json.loads(os.environ["ROLE_JSON"])
rules = data.get("rules", [])
if len(rules) != 1:
    print("Role pod-viewer must contain exactly one rule", file=sys.stderr)
    sys.exit(1)
rule = rules[0]
if sorted(rule.get("apiGroups", [])) not in ([], [""]):
    print("Role pod-viewer must target the core API group only", file=sys.stderr)
    sys.exit(1)
if sorted(rule.get("resources", [])) != ["pods"]:
    print("Role pod-viewer must allow only pods", file=sys.stderr)
    sys.exit(1)
if sorted(rule.get("verbs", [])) != ["list"]:
    print("Role pod-viewer must allow only list", file=sys.stderr)
    sys.exit(1)
if any(key in rule for key in ("resourceNames", "nonResourceURLs")):
    print("Role pod-viewer must not include resourceNames or nonResourceURLs", file=sys.stderr)
    sys.exit(1)
PY

binding_ref="$(kubectl get rolebinding pod-viewer-bind -n default -o jsonpath='{.roleRef.kind}:{.roleRef.name}')"
[ "${binding_ref}" = "Role:pod-viewer" ] || fail "RoleBinding pod-viewer-bind must reference Role pod-viewer"

binding_subject="$(kubectl get rolebinding pod-viewer-bind -n default -o jsonpath='{.subjects[0].kind}:{.subjects[0].name}:{.subjects[0].namespace}')"
[ "${binding_subject}" = "ServiceAccount:viewer-sa:default" ] || fail "RoleBinding pod-viewer-bind must bind ServiceAccount viewer-sa in default"

list_allowed="$(kubectl auth can-i list pods -n default --as=system:serviceaccount:default:viewer-sa)"
[ "${list_allowed}" = "yes" ] || fail "viewer-sa cannot list pods in namespace default"

for verb in get watch create update delete patch; do
  allowed="$(kubectl auth can-i "${verb}" pods -n default --as=system:serviceaccount:default:viewer-sa || true)"
  if [ "${allowed}" = "yes" ]; then
    fail "viewer-sa must not be allowed to ${verb} pods in namespace default"
  fi
done

echo "Verification passed"
