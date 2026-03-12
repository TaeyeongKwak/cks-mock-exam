#!/bin/bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

binding_role="$(kubectl get rolebinding role-a-bind -n access-lab -o jsonpath='{.roleRef.kind}:{.roleRef.name}' 2>/dev/null || true)"
[ "${binding_role}" = "Role:role-a" ] || fail "RoleBinding role-a-bind must still reference Role role-a"

subject="$(kubectl get rolebinding role-a-bind -n access-lab -o jsonpath='{.subjects[0].kind}:{.subjects[0].name}:{.subjects[0].namespace}' 2>/dev/null || true)"
[ "${subject}" = "ServiceAccount:sa-app-1:access-lab" ] || fail "RoleBinding role-a-bind must bind ServiceAccount sa-app-1 in namespace access-lab"

rule_count="$(kubectl get role role-a -n access-lab -o jsonpath='{.rules[*].resources}' | wc -w | tr -d ' ')"
[ "${rule_count}" -eq 1 ] || fail "Role role-a must contain only one resource rule"

resources="$(kubectl get role role-a -n access-lab -o jsonpath='{.rules[0].resources[*]}')"
verbs="$(kubectl get role role-a -n access-lab -o jsonpath='{.rules[0].verbs[*]}')"
api_groups="$(kubectl get role role-a -n access-lab -o jsonpath='{.rules[0].apiGroups[*]}')"

[ "${resources}" = "services" ] || fail "Role role-a must allow only services"
[ "${verbs}" = "watch" ] || fail "Role role-a must allow only watch"
[ -z "${api_groups}" ] || [ "${api_groups}" = "" ] || fail "Role role-a must target the core API group only"

kubectl get clusterrole role-b >/dev/null 2>&1 || fail "ClusterRole role-b not found"
cr_resources="$(kubectl get clusterrole role-b -o jsonpath='{.rules[0].resources[*]}')"
cr_verbs="$(kubectl get clusterrole role-b -o jsonpath='{.rules[0].verbs[*]}')"
cr_rule_count="$(kubectl get clusterrole role-b -o jsonpath='{.rules[*].resources}' | wc -w | tr -d ' ')"

[ "${cr_rule_count}" -eq 1 ] || fail "ClusterRole role-b must contain only one resource rule"
[ "${cr_resources}" = "namespaces" ] || fail "ClusterRole role-b must allow only namespaces"
[ "${cr_verbs}" = "update" ] || fail "ClusterRole role-b must allow only update"

kubectl get clusterrolebinding role-b-bind >/dev/null 2>&1 || fail "ClusterRoleBinding role-b-bind not found"
cluster_binding_role="$(kubectl get clusterrolebinding role-b-bind -o jsonpath='{.roleRef.kind}:{.roleRef.name}')"
[ "${cluster_binding_role}" = "ClusterRole:role-b" ] || fail "ClusterRoleBinding role-b-bind must reference ClusterRole role-b"

cluster_subject="$(kubectl get clusterrolebinding role-b-bind -o jsonpath='{.subjects[0].kind}:{.subjects[0].name}:{.subjects[0].namespace}')"
[ "${cluster_subject}" = "ServiceAccount:sa-app-1:access-lab" ] || fail "ClusterRoleBinding role-b-bind must bind ServiceAccount sa-app-1 in namespace access-lab"

kubectl get pod frontend-pod -n access-lab -o jsonpath='{.spec.serviceAccountName}' | grep -qx 'sa-app-1' || fail "Pod frontend-pod must use ServiceAccount sa-app-1"

watch_services="$(kubectl auth can-i watch services -n access-lab --as=system:serviceaccount:access-lab:sa-app-1)"
[ "${watch_services}" = "yes" ] || fail "sa-app-1 cannot watch services in namespace access-lab"

get_services="$(kubectl auth can-i get services -n access-lab --as=system:serviceaccount:access-lab:sa-app-1 || true)"
if [ "${get_services}" = "yes" ]; then
  fail "sa-app-1 must not get services in namespace access-lab"
fi

list_services="$(kubectl auth can-i list services -n access-lab --as=system:serviceaccount:access-lab:sa-app-1 || true)"
if [ "${list_services}" = "yes" ]; then
  fail "sa-app-1 must not list services in namespace access-lab"
fi

update_namespaces="$(kubectl auth can-i update namespaces --as=system:serviceaccount:access-lab:sa-app-1)"
[ "${update_namespaces}" = "yes" ] || fail "sa-app-1 cannot update namespaces through ClusterRole role-b"

create_namespaces="$(kubectl auth can-i create namespaces --as=system:serviceaccount:access-lab:sa-app-1 || true)"
if [ "${create_namespaces}" = "yes" ]; then
  fail "sa-app-1 must not create namespaces"
fi

echo "Verification passed"
