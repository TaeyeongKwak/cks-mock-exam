#!/bin/bash
set -euo pipefail

MANIFEST="/root/kubesec-test.yaml"

fail() {
  echo "$1" >&2
  exit 1
}

[ -f "${MANIFEST}" ] || fail "Manifest not found at ${MANIFEST}"

kubectl apply --dry-run=client -f "${MANIFEST}" >/dev/null 2>&1 || fail "Manifest is not valid for kubectl"

pod_name="$(kubectl create --dry-run=client -f "${MANIFEST}" -o jsonpath='{.metadata.name}' 2>/dev/null)"
[ "${pod_name}" = "kubesec-demo" ] || fail "Pod name must remain kubesec-demo"

run_as_non_root="$(kubectl create --dry-run=client -f "${MANIFEST}" -o jsonpath='{.spec.containers[0].securityContext.runAsNonRoot}' 2>/dev/null)"
[ "${run_as_non_root}" = "true" ] || fail "runAsNonRoot must be true"

run_as_user="$(kubectl create --dry-run=client -f "${MANIFEST}" -o jsonpath='{.spec.containers[0].securityContext.runAsUser}' 2>/dev/null)"
[ "${run_as_user}" = "1000" ] || fail "runAsUser must be 1000"

allow_pe="$(kubectl create --dry-run=client -f "${MANIFEST}" -o jsonpath='{.spec.containers[0].securityContext.allowPrivilegeEscalation}' 2>/dev/null)"
[ "${allow_pe}" = "false" ] || fail "allowPrivilegeEscalation must be false"

read_only_root="$(kubectl create --dry-run=client -f "${MANIFEST}" -o jsonpath='{.spec.containers[0].securityContext.readOnlyRootFilesystem}' 2>/dev/null)"
[ "${read_only_root}" = "true" ] || fail "readOnlyRootFilesystem must be true"

drop_caps="$(kubectl create --dry-run=client -f "${MANIFEST}" -o jsonpath='{.spec.containers[0].securityContext.capabilities.drop[*]}' 2>/dev/null)"
[[ " ${drop_caps} " == *" ALL "* ]] || fail "capabilities.drop must include ALL"

add_caps="$(kubectl create --dry-run=client -f "${MANIFEST}" -o jsonpath='{.spec.containers[0].securityContext.capabilities.add[*]}' 2>/dev/null || true)"
[ -z "${add_caps}" ] || fail "capabilities.add must be removed"

scan_output="$(kubesec scan "${MANIFEST}")"
score="$(printf '%s' "${scan_output}" | python3 -c 'import json,sys; data=json.load(sys.stdin); print(data[0]["score"])')"

if [ -z "${score}" ] || [ "${score}" -lt 4 ]; then
  fail "KubeSec score must be at least 4"
fi

echo "Verification passed"
