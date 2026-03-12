#!/bin/bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

binding_role="$(kubectl get rolebinding app-role-a-bind -n data-core -o jsonpath='{.roleRef.kind}:{.roleRef.name}' 2>/dev/null || true)"
[ "${binding_role}" = "Role:app-role-a" ] || fail "RoleBinding app-role-a-bind must still reference Role app-role-a"

subject="$(kubectl get rolebinding app-role-a-bind -n data-core -o jsonpath='{.subjects[0].kind}:{.subjects[0].name}:{.subjects[0].namespace}' 2>/dev/null || true)"
[ "${subject}" = "ServiceAccount:app-sa:data-core" ] || fail "RoleBinding app-role-a-bind must bind ServiceAccount app-sa in namespace data-core"

rule_count="$(kubectl get role app-role-a -n data-core -o jsonpath='{.rules[*].resources}' | wc -w | tr -d ' ')"
[ "${rule_count}" -eq 1 ] || fail "Role app-role-a must contain only one resource rule"

resources="$(kubectl get role app-role-a -n data-core -o jsonpath='{.rules[0].resources[*]}')"
verbs="$(kubectl get role app-role-a -n data-core -o jsonpath='{.rules[0].verbs[*]}')"
api_groups="$(kubectl get role app-role-a -n data-core -o jsonpath='{.rules[0].apiGroups[*]}')"

[ "${resources}" = "pods" ] || fail "Role app-role-a must allow only pods"
[ "${verbs}" = "get" ] || fail "Role app-role-a must allow only get"
[ -z "${api_groups}" ] || [ "${api_groups}" = "" ] || fail "Role app-role-a must target the core API group only"

kubectl get role app-role-b -n data-core >/dev/null 2>&1 || fail "Role app-role-b not found in data-core"
role2_resources="$(kubectl get role app-role-b -n data-core -o jsonpath='{.rules[0].resources[*]}')"
role2_verbs="$(kubectl get role app-role-b -n data-core -o jsonpath='{.rules[0].verbs[*]}')"
role2_api_groups="$(kubectl get role app-role-b -n data-core -o jsonpath='{.rules[0].apiGroups[*]}')"
role2_rule_count="$(kubectl get role app-role-b -n data-core -o jsonpath='{.rules[*].resources}' | wc -w | tr -d ' ')"

[ "${role2_rule_count}" -eq 1 ] || fail "Role app-role-b must contain only one resource rule"
[ "${role2_resources}" = "statefulsets" ] || fail "Role app-role-b must allow only statefulsets"
[ "${role2_verbs}" = "update" ] || fail "Role app-role-b must allow only update"
[ "${role2_api_groups}" = "apps" ] || fail "Role app-role-b must target the apps API group"

kubectl get rolebinding app-role-b-bind -n data-core >/dev/null 2>&1 || fail "RoleBinding app-role-b-bind not found in data-core"
role2_binding_ref="$(kubectl get rolebinding app-role-b-bind -n data-core -o jsonpath='{.roleRef.kind}:{.roleRef.name}')"
[ "${role2_binding_ref}" = "Role:app-role-b" ] || fail "RoleBinding app-role-b-bind must reference Role app-role-b"

role2_subject="$(kubectl get rolebinding app-role-b-bind -n data-core -o jsonpath='{.subjects[0].kind}:{.subjects[0].name}:{.subjects[0].namespace}')"
[ "${role2_subject}" = "ServiceAccount:app-sa:data-core" ] || fail "RoleBinding app-role-b-bind must bind ServiceAccount app-sa in namespace data-core"

kubectl get pod frontend-agent -n data-core -o jsonpath='{.spec.serviceAccountName}' | grep -qx 'app-sa' || fail "Pod frontend-agent must use ServiceAccount app-sa"

get_pods="$(kubectl auth can-i get pods -n data-core --as=system:serviceaccount:data-core:app-sa)"
[ "${get_pods}" = "yes" ] || fail "app-sa cannot get pods in namespace data-core"

list_pods="$(kubectl auth can-i list pods -n data-core --as=system:serviceaccount:data-core:app-sa || true)"
if [ "${list_pods}" = "yes" ]; then
  fail "app-sa must not list pods in namespace data-core"
fi

watch_pods="$(kubectl auth can-i watch pods -n data-core --as=system:serviceaccount:data-core:app-sa || true)"
if [ "${watch_pods}" = "yes" ]; then
  fail "app-sa must not watch pods in namespace data-core"
fi

get_services="$(kubectl auth can-i get services -n data-core --as=system:serviceaccount:data-core:app-sa || true)"
if [ "${get_services}" = "yes" ]; then
  fail "app-sa must not get services in namespace data-core"
fi

update_statefulsets="$(kubectl auth can-i update statefulsets.apps -n data-core --as=system:serviceaccount:data-core:app-sa)"
[ "${update_statefulsets}" = "yes" ] || fail "app-sa cannot update statefulsets in namespace data-core through Role app-role-b"

create_statefulsets="$(kubectl auth can-i create statefulsets.apps -n data-core --as=system:serviceaccount:data-core:app-sa || true)"
if [ "${create_statefulsets}" = "yes" ]; then
  fail "app-sa must not create statefulsets in namespace data-core"
fi

echo "Verification passed"
