#!/bin/bash
set -euo pipefail

MANIFEST_DIR="${SCENARIO_MANIFEST_DIR:-/home/review-manifests}"
DOCKERFILE="${MANIFEST_DIR}/Dockerfile"
DEPLOYMENT="${MANIFEST_DIR}/deployment.yaml"

fail() {
  echo "$1" >&2
  exit 1
}

[ -f "${DOCKERFILE}" ] || fail "Dockerfile not found at ${DOCKERFILE}"
[ -f "${DEPLOYMENT}" ] || fail "Deployment manifest not found at ${DEPLOYMENT}"

from_line="$(grep -E '^[[:space:]]*FROM[[:space:]]+' "${DOCKERFILE}" | head -n 1 | tr -d '\r')"
[ "${from_line}" = "FROM ubuntu:20.04" ] || fail "Dockerfile must keep FROM ubuntu:20.04"

grep -Eiq 'useradd|adduser' "${DOCKERFILE}" || fail "Dockerfile must define user nobody with UID 65535"
grep -Eq '(useradd|adduser).*(nobody|65535)|(nobody|65535).*(useradd|adduser)' "${DOCKERFILE}" || fail "Dockerfile must define user nobody with UID 65535"
grep -Eq '(useradd|adduser).*(-u[[:space:]]*65535|65535).*(nobody)|(useradd|adduser).*(nobody).*(-u[[:space:]]*65535|65535)' "${DOCKERFILE}" || fail "Dockerfile must assign UID 65535 to user nobody"
grep -Eq '(useradd|adduser).*(-u[[:space:]]*0|root)' "${DOCKERFILE}" && fail "Dockerfile must not create or configure a root user entry for the application user"

user_line="$(grep -E '^[[:space:]]*USER[[:space:]]+' "${DOCKERFILE}" | head -n 1 | tr -d '\r')"
[ -n "${user_line}" ] || fail "Dockerfile must contain a USER line"
echo "${user_line}" | grep -Eq '^USER[[:space:]]+(nobody|65535)$' || fail "Dockerfile must run as nobody or UID 65535"
echo "${user_line}" | grep -Eiq '^USER[[:space:]]+root$' && fail "Dockerfile must not run as root"

grep -Eq '^kind:[[:space:]]*Deployment[[:space:]]*$' "${DEPLOYMENT}" || fail "Manifest must remain a Deployment"
grep -Eq '^  name:[[:space:]]*security-review-demo[[:space:]]*$' "${DEPLOYMENT}" || fail "Deployment name must remain security-review-demo"
grep -Eq '^ {10}runAsUser:[[:space:]]*65535[[:space:]]*$' "${DEPLOYMENT}" || fail "Container securityContext.runAsUser must be 65535"
grep -Eq '^ {10}runAsNonRoot:[[:space:]]*true[[:space:]]*$' "${DEPLOYMENT}" || fail "Container securityContext.runAsNonRoot must be true"
grep -Eq '^ {10}runAsUser:[[:space:]]*0[[:space:]]*$' "${DEPLOYMENT}" && fail "Container must not run as UID 0"
grep -Eq '^ {10}runAsNonRoot:[[:space:]]*false[[:space:]]*$' "${DEPLOYMENT}" && fail "Container must not disable runAsNonRoot"

echo "Verification passed"
