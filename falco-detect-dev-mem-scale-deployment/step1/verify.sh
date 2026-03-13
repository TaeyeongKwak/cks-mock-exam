#!/bin/bash
set -euo pipefail

RULE_FILE="/root/rule.yaml"

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get deployment mem-hacker -n default >/dev/null 2>&1 || fail "Deployment mem-hacker not found in namespace default"

[ -f "${RULE_FILE}" ] || fail "Custom Falco rule file not found at ${RULE_FILE}"

grep -Eq 'evt\.is_open_read=true' "${RULE_FILE}" || fail "rule.yaml is missing evt.is_open_read=true condition"
grep -Eq 'evt\.is_open_write=true' "${RULE_FILE}" || fail "rule.yaml is missing evt.is_open_write=true condition"
grep -Eq 'fd\.name[[:space:]]+contains[[:space:]]+/dev/mem' "${RULE_FILE}" || fail "rule.yaml is missing /dev/mem match condition"

replicas="$(kubectl get deployment mem-hacker -n default -o jsonpath='{.spec.replicas}')"
[ "${replicas}" = "0" ] || fail "Deployment mem-hacker replicas must be 0 (current: ${replicas})"

ready="$(kubectl get deployment mem-hacker -n default -o jsonpath='{.status.readyReplicas}')"
ready="${ready:-0}"
[ "${ready}" = "0" ] || fail "Deployment mem-hacker still has ready replicas (${ready})"

echo "Verification passed"