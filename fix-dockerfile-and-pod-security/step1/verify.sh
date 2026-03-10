#!/bin/bash
set -euo pipefail

DOCKERFILE="/root/Dockerfile"
PODFILE="/root/pod-security-audit.yaml"

fail() {
  echo "$1" >&2
  exit 1
}

[ -f "${DOCKERFILE}" ] || fail "Dockerfile not found at ${DOCKERFILE}"
[ -f "${PODFILE}" ] || fail "Pod manifest not found at ${PODFILE}"

from_line="$(grep -E '^[[:space:]]*FROM[[:space:]]+' "${DOCKERFILE}" | head -n 1 | tr -d '\r')"
[ -n "${from_line}" ] || fail "Dockerfile must contain a FROM line"
echo "${from_line}" | grep -Eq '^FROM[[:space:]]+ubuntu:' || fail "Dockerfile must still use an ubuntu base image"
echo "${from_line}" | grep -Eq ':latest([[:space:]]|$)' && fail "Dockerfile must not use ubuntu:latest"

grep -Eiq 'useradd|adduser' "${DOCKERFILE}" || fail "Dockerfile must create a non-root user"
grep -Eq '(useradd|adduser).*(test-user|5375)|(test-user|5375).*(useradd|adduser)' "${DOCKERFILE}" || fail "Dockerfile must create test-user with UID 5375"

user_line="$(grep -E '^[[:space:]]*USER[[:space:]]+' "${DOCKERFILE}" | head -n 1 | tr -d '\r')"
[ -n "${user_line}" ] || fail "Dockerfile must contain a USER line"
echo "${user_line}" | grep -Eq '^USER[[:space:]]+(test-user|5375)$' || fail "Dockerfile must run as test-user or UID 5375"
echo "${user_line}" | grep -Eiq '^USER[[:space:]]+root$' && fail "Dockerfile must not run as root"

kubectl apply --dry-run=client -f "${PODFILE}" >/dev/null 2>&1 || fail "Pod manifest is not valid YAML for kubectl"

pod_name="$(kubectl create --dry-run=client -f "${PODFILE}" -o jsonpath='{.metadata.name}' 2>/dev/null)"
[ "${pod_name}" = "security-audit-pod" ] || fail "Pod name must remain security-audit-pod"

container_run_as_user="$(kubectl create --dry-run=client -f "${PODFILE}" -o jsonpath='{.spec.containers[0].securityContext.runAsUser}' 2>/dev/null)"
[ "${container_run_as_user}" = "5375" ] || fail "Container securityContext.runAsUser must be 5375"

privileged_value="$(kubectl create --dry-run=client -f "${PODFILE}" -o jsonpath='{.spec.containers[0].securityContext.privileged}' 2>/dev/null)"
[ "${privileged_value}" = "false" ] || fail "Container securityContext.privileged must be false"

allow_pe="$(kubectl create --dry-run=client -f "${PODFILE}" -o jsonpath='{.spec.containers[0].securityContext.allowPrivilegeEscalation}' 2>/dev/null)"
[ "${allow_pe}" = "false" ] || fail "allowPrivilegeEscalation must remain false"

echo "Verification passed"
