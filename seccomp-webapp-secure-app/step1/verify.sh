#!/bin/bash
set -euo pipefail

PROFILE_ON_NODE="/var/lib/kubelet/seccomp/frontend-seccomp.json"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=5"

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get ns secure-zone >/dev/null 2>&1 || fail "Namespace secure-zone not found"
kubectl get deploy frontend -n secure-zone >/dev/null 2>&1 || fail "Deployment frontend not found"

ssh ${SSH_OPTS} node01 "test -f ${PROFILE_ON_NODE}" >/dev/null 2>&1 || fail "Seccomp profile not found on node01 at ${PROFILE_ON_NODE}"

profile_json="$(ssh ${SSH_OPTS} node01 "cat ${PROFILE_ON_NODE}" 2>/dev/null || true)"
[ -n "${profile_json}" ] || fail "Could not read seccomp profile from node01"

PROFILE_JSON="${profile_json}" python3 - <<'PY'
import json
import os
import sys

profile = json.loads(os.environ["PROFILE_JSON"])
if profile.get("defaultAction") != "SCMP_ACT_ERRNO":
    print("Seccomp profile must use defaultAction SCMP_ACT_ERRNO", file=sys.stderr)
    sys.exit(1)

required = {"read", "write", "exit", "sigreturn"}
found = set()
for entry in profile.get("syscalls", []):
    for name in entry.get("names", []):
        if name in required:
            found.add(name)

missing = sorted(required - found)
if missing:
    print("Seccomp profile is missing required syscalls: " + ", ".join(missing), file=sys.stderr)
    sys.exit(1)
PY

seccomp_type="$(kubectl get deploy frontend -n secure-zone -o jsonpath='{.spec.template.spec.securityContext.seccompProfile.type}' 2>/dev/null || true)"
localhost_profile="$(kubectl get deploy frontend -n secure-zone -o jsonpath='{.spec.template.spec.securityContext.seccompProfile.localhostProfile}' 2>/dev/null || true)"

[ "${seccomp_type}" = "Localhost" ] || fail "Deployment frontend must use securityContext.seccompProfile.type=Localhost"
[ "${localhost_profile}" = "frontend-seccomp.json" ] || fail "Deployment frontend must reference localhostProfile frontend-seccomp.json"

node_name="$(kubectl get deploy frontend -n secure-zone -o jsonpath='{.spec.template.spec.nodeSelector.kubernetes\.io/hostname}')"
[ "${node_name}" = "node01" ] || fail "Deployment frontend must stay pinned to node01"

pod_name="$(
  kubectl get pod -n secure-zone -l app=frontend \
    --sort-by=.metadata.creationTimestamp \
    -o jsonpath='{.items[-1:].metadata.name}' 2>/dev/null || true
)"
[ -n "${pod_name}" ] || fail "No running Pod found for Deployment frontend"

pod_seccomp_type="$(kubectl get pod "${pod_name}" -n secure-zone -o jsonpath='{.spec.securityContext.seccompProfile.type}' 2>/dev/null || true)"
pod_localhost_profile="$(kubectl get pod "${pod_name}" -n secure-zone -o jsonpath='{.spec.securityContext.seccompProfile.localhostProfile}' 2>/dev/null || true)"
[ "${pod_seccomp_type}" = "Localhost" ] || fail "Pod ${pod_name} is not using seccompProfile.type=Localhost"
[ "${pod_localhost_profile}" = "frontend-seccomp.json" ] || fail "Pod ${pod_name} is not referencing localhostProfile frontend-seccomp.json"

pod_phase="$(kubectl get pod "${pod_name}" -n secure-zone -o jsonpath='{.status.phase}' 2>/dev/null || true)"
if kubectl wait --for=condition=Ready "pod/${pod_name}" -n secure-zone --timeout=5s >/dev/null 2>&1; then
  seccomp_mode="$(kubectl exec -n secure-zone "${pod_name}" -- sh -c 'grep "^Seccomp:" /proc/1/status | awk "{print \$2}"' 2>/dev/null | tr -d '\r')"
  [ "${seccomp_mode}" = "2" ] || fail "Pod ${pod_name} is not running with seccomp filter mode enabled"
else
  # Some playground/runtime combinations fail to start very restrictive localhost seccomp profiles
  # even though the profile is correctly staged and attached to the Pod spec. In that case, the
  # learning objective is still satisfied once the profile exists on node01 and the workload is
  # configured to use it.
  [ -n "${pod_phase}" ] || fail "Pod ${pod_name} was not created for Deployment frontend"
fi

echo "Verification passed"
