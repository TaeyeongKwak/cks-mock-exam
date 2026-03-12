#!/bin/bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get namespace qa-system >/dev/null 2>&1 || fail "Namespace qa-system not found"
kubectl get pod web-pod -n qa-system >/dev/null 2>&1 || fail "Pod web-pod not found in qa-system"

sa_name="$(kubectl get pod web-pod -n qa-system -o jsonpath='{.spec.serviceAccountName}')"
[ -n "${sa_name}" ] || fail "Pod web-pod does not have a ServiceAccount name"

[ -f /candidate/current-sa.txt ] || fail "File /candidate/current-sa.txt not found"
file_sa="$(tr -d '\r\n' </candidate/current-sa.txt)"
[ "${file_sa}" = "${sa_name}" ] || fail "/candidate/current-sa.txt must contain the ServiceAccount name ${sa_name}"

matches="$(SA_NAME="${sa_name}" python3 - <<'PY'
import json
import os
import subprocess
import sys

sa_name = os.environ["SA_NAME"]

roles = json.loads(subprocess.check_output(
    ["kubectl", "get", "role", "-n", "qa-system", "-o", "json"],
    text=True,
))["items"]
bindings = json.loads(subprocess.check_output(
    ["kubectl", "get", "rolebinding", "-n", "qa-system", "-o", "json"],
    text=True,
))["items"]

matching_roles = set()
for role in roles:
    rules = role.get("rules", [])
    if len(rules) != 1:
        continue
    rule = rules[0]
    if sorted(rule.get("apiGroups", [])) != ["apps"]:
        continue
    if sorted(rule.get("resources", [])) != ["deployments"]:
        continue
    if sorted(rule.get("verbs", [])) != ["get", "list", "watch"]:
        continue
    if any(key in rule for key in ("resourceNames", "nonResourceURLs")):
        continue
    matching_roles.add(role["metadata"]["name"])

count = 0
for binding in bindings:
    role_ref = binding.get("roleRef", {})
    if role_ref.get("kind") != "Role":
        continue
    if role_ref.get("name") not in matching_roles:
        continue
    for subject in binding.get("subjects", []) or []:
        if subject.get("kind") == "ServiceAccount" and subject.get("name") == sa_name and subject.get("namespace", "qa-system") == "qa-system":
            count += 1
            break

print(count)
PY
)"

[ "${matches}" -ge 1 ] || fail "No RoleBinding in qa-system binds ${sa_name} to a Role granting only get, list, and watch on deployments"

for verb in get list watch; do
  allowed="$(kubectl auth can-i "${verb}" deployments -n qa-system --as=system:serviceaccount:qa-system:${sa_name})"
  [ "${allowed}" = "yes" ] || fail "${sa_name} cannot ${verb} deployments in namespace qa-system"
done

create_allowed="$(kubectl auth can-i create deployments -n qa-system --as=system:serviceaccount:qa-system:${sa_name} || true)"
if [ "${create_allowed}" = "yes" ]; then
  fail "${sa_name} must not be able to create deployments in namespace qa-system"
fi

delete_allowed="$(kubectl auth can-i delete deployments -n qa-system --as=system:serviceaccount:qa-system:${sa_name} || true)"
if [ "${delete_allowed}" = "yes" ]; then
  fail "${sa_name} must not be able to delete deployments in namespace qa-system"
fi

echo "Verification passed"
