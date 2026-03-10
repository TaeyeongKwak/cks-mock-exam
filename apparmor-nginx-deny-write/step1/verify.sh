#!/bin/bash
set -euo pipefail

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get pod cache-probe >/dev/null 2>&1 || fail "Pod cache-probe not found"

if ! ssh ${SSH_OPTS} node01 "grep -q '^cache-lockdown ' /sys/kernel/security/apparmor/profiles"; then
  fail "Profile cache-lockdown is not loaded on node01"
fi

node_name="$(kubectl get pod cache-probe -o jsonpath='{.spec.nodeName}')"
[ "${node_name}" = "node01" ] || fail "Pod cache-probe is not scheduled on node01"

kubectl wait --for=condition=Ready pod/cache-probe --timeout=120s >/dev/null 2>&1 || fail "Pod cache-probe is not Ready"

pod_type="$(kubectl get pod cache-probe -o jsonpath='{.spec.securityContext.appArmorProfile.type}' 2>/dev/null || true)"
pod_profile="$(kubectl get pod cache-probe -o jsonpath='{.spec.securityContext.appArmorProfile.localhostProfile}' 2>/dev/null || true)"
container_type="$(kubectl get pod cache-probe -o jsonpath='{.spec.containers[0].securityContext.appArmorProfile.type}' 2>/dev/null || true)"
container_profile="$(kubectl get pod cache-probe -o jsonpath='{.spec.containers[0].securityContext.appArmorProfile.localhostProfile}' 2>/dev/null || true)"
annotation_profile="$(kubectl get pod cache-probe -o go-template='{{index .metadata.annotations "container.apparmor.security.beta.kubernetes.io/probe"}}' 2>/dev/null || true)"

if [ "${pod_type}" = "Localhost" ] && [ "${pod_profile}" = "cache-lockdown" ]; then
  :
elif [ "${container_type}" = "Localhost" ] && [ "${container_profile}" = "cache-lockdown" ]; then
  :
elif [ "${annotation_profile}" = "localhost/cache-lockdown" ]; then
  :
else
  fail "Pod manifest does not reference cache-lockdown"
fi

current_profile="$(kubectl exec cache-probe -- cat /proc/1/attr/current 2>/dev/null || true)"
echo "${current_profile}" | grep -q 'cache-lockdown' || fail "AppArmor profile is not active inside the container"

if kubectl exec cache-probe -- sh -c 'echo blocked >/var/cache/demo/write-check' >/dev/null 2>&1; then
  fail "Write attempt into /var/cache/demo succeeded unexpectedly"
fi

if kubectl exec cache-probe -- sh -c 'test -f /var/cache/demo/write-check' >/dev/null 2>&1; then
  fail "Container created /var/cache/demo/write-check despite the AppArmor policy"
fi

echo "Verification passed"
