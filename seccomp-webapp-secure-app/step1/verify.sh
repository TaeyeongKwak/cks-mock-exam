#!/bin/bash
set -euo pipefail

PROFILE_ON_NODE="/var/lib/kubelet/seccomp/frontend-seccomp.json"

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get ns secure-zone >/dev/null 2>&1 || fail "Namespace secure-zone not found"
kubectl get deploy frontend -n secure-zone >/dev/null 2>&1 || fail "Deployment frontend not found"

ssh node01 "test -f ${PROFILE_ON_NODE}" >/dev/null 2>&1 || fail "Seccomp profile not found on node01 at ${PROFILE_ON_NODE}"

profile_json="$(ssh node01 "cat ${PROFILE_ON_NODE}" 2>/dev/null || true)"
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

kubectl rollout status deployment/frontend -n secure-zone --timeout=180s >/dev/null 2>&1 || fail "Deployment frontend is not successfully rolled out"
pod_name="$(kubectl get pod -n secure-zone -l app=frontend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
[ -n "${pod_name}" ] || fail "No running Pod found for Deployment frontend"

kubectl wait --for=condition=Ready "pod/${pod_name}" -n secure-zone --timeout=120s >/dev/null 2>&1 || fail "Pod ${pod_name} is not Ready"

seccomp_mode="$(kubectl exec -n secure-zone "${pod_name}" -- sh -c 'grep "^Seccomp:" /proc/1/status | awk "{print \$2}"' 2>/dev/null | tr -d '\r')"
[ "${seccomp_mode}" = "2" ] || fail "Pod ${pod_name} is not running with seccomp filter mode enabled"

echo "Verification passed"
