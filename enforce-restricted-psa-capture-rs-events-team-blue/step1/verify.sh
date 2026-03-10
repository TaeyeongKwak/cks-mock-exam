#!/bin/bash
set -euo pipefail

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
LOG_FILE="/opt/records/psa-fail.log"

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get namespace ops-blue >/dev/null 2>&1 || fail "Namespace ops-blue not found"

enforce_label="$(kubectl get namespace ops-blue -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}')"
[ "${enforce_label}" = "restricted" ] || fail "Namespace ops-blue must enforce the restricted policy"

enforce_version="$(kubectl get namespace ops-blue -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce-version}' 2>/dev/null || true)"
[ -n "${enforce_version}" ] || fail "Namespace ops-blue must set pod-security.kubernetes.io/enforce-version"

kubectl get deployment debug-runner -n ops-blue >/dev/null 2>&1 || fail "Deployment debug-runner not found"

ready_replicas="$(kubectl get deployment debug-runner -n ops-blue -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)"
[ -z "${ready_replicas}" ] || [ "${ready_replicas}" = "0" ] || fail "Deployment debug-runner should not have ready replicas after enforcement"

pod_count="$(kubectl get pods -n ops-blue -l app=debug-runner --no-headers 2>/dev/null | wc -l | tr -d ' ')"
[ "${pod_count}" = "0" ] || fail "Debug runner Pods should not be running after enforcement"

rs_name="$(kubectl get rs -n ops-blue -l app=debug-runner -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
[ -n "${rs_name}" ] || fail "ReplicaSet for debug-runner not found"

event_text="$(kubectl describe rs "${rs_name}" -n ops-blue 2>/dev/null || true)"
echo "${event_text}" | grep -Eiq 'FailedCreate|Error creating|violates PodSecurity|restricted' || fail "ReplicaSet events do not show Pod Security Admission blocking recreation"

if ! ssh ${SSH_OPTS} node01 "test -f ${LOG_FILE}"; then
  fail "Log file not found at node01:${LOG_FILE}"
fi

file_contents="$(ssh ${SSH_OPTS} node01 "cat ${LOG_FILE}" 2>/dev/null || true)"
[ -n "${file_contents}" ] || fail "Log file on node01 is empty"

FILE_CONTENTS="${file_contents}" python3 - <<'PY' || exit 1
import os
import sys

text = os.environ["FILE_CONTENTS"]
required = ["FailedCreate", "restricted", "PodSecurity"]
if not any(token in text for token in required):
    print("Saved log lines do not show Pod Security Admission failure details", file=sys.stderr)
    sys.exit(1)
if "privileged" not in text and "allowPrivilegeEscalation" not in text and "capabilities" not in text:
    print("Saved log lines do not include a concrete restricted-policy failure reason", file=sys.stderr)
    sys.exit(1)
PY

echo "Verification passed"
