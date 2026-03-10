#!/bin/bash
set -euo pipefail

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get pod web-guard >/dev/null 2>&1 || fail "Pod web-guard not found"

if ! ssh ${SSH_OPTS} node01 "grep -q '^web-guard ' /sys/kernel/security/apparmor/profiles"; then
  fail "Profile web-guard is not loaded on node01"
fi

node_name="$(kubectl get pod web-guard -o jsonpath='{.spec.nodeName}')"
[ "${node_name}" = "node01" ] || fail "Pod web-guard is not scheduled on node01"

kubectl wait --for=condition=Ready pod/web-guard --timeout=120s >/dev/null 2>&1 || fail "Pod web-guard is not Ready"

pod_type="$(kubectl get pod web-guard -o jsonpath='{.spec.securityContext.appArmorProfile.type}' 2>/dev/null || true)"
pod_profile="$(kubectl get pod web-guard -o jsonpath='{.spec.securityContext.appArmorProfile.localhostProfile}' 2>/dev/null || true)"
container_type="$(kubectl get pod web-guard -o jsonpath='{.spec.containers[0].securityContext.appArmorProfile.type}' 2>/dev/null || true)"
container_profile="$(kubectl get pod web-guard -o jsonpath='{.spec.containers[0].securityContext.appArmorProfile.localhostProfile}' 2>/dev/null || true)"
annotation_profile="$(kubectl get pod web-guard -o go-template='{{index .metadata.annotations "container.apparmor.security.beta.kubernetes.io/web"}}' 2>/dev/null || true)"

if [ "${pod_type}" = "Localhost" ] && [ "${pod_profile}" = "web-guard" ]; then
  :
elif [ "${container_type}" = "Localhost" ] && [ "${container_profile}" = "web-guard" ]; then
  :
elif [ "${annotation_profile}" = "localhost/web-guard" ]; then
  :
else
  fail "Pod manifest does not reference web-guard"
fi

current_profile="$(kubectl exec web-guard -- cat /proc/1/attr/current 2>/dev/null || true)"
echo "${current_profile}" | grep -q 'web-guard' || fail "AppArmor profile is not applied inside the container"

echo "Verification passed"
