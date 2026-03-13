#!/bin/bash
set -euo pipefail

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
TARGET_FILE="/home/anomalous/report"
RULE_FILE="/etc/falco/falco_rules.local.yaml"

fail() {
  echo "$1" >&2
  exit 1
}

if ! ssh ${SSH_OPTS} node01 "test -f ${RULE_FILE}"; then
  fail "Falco local rules file not found on node01: ${RULE_FILE}"
fi

if ! ssh ${SSH_OPTS} node01 "grep -Eq 'condition:.*spawned_process.*container.*k8s\.pod\.name.?=.?tomcat|condition:.*k8s\.pod\.name.?=.?tomcat.*spawned_process.*container|condition:.*container.*spawned_process.*k8s\.pod\.name.?=.?tomcat' ${RULE_FILE}"; then
  fail "Falco rule must detect spawned processes"
fi

if ! ssh ${SSH_OPTS} node01 "grep -Eq 'condition:.*k8s\.pod\.name.?=.?tomcat' ${RULE_FILE}"; then
  fail "Falco rule must target Pod tomcat"
fi

if ! ssh ${SSH_OPTS} node01 "grep -Eq '\[%evt.time\],\[%user\.(uid|name)\],\[%proc.name\]' ${RULE_FILE}"; then
  fail "Falco rule output must emit [timestamp],[uid],[processName]"
fi

if ! ssh ${SSH_OPTS} node01 "test -f ${TARGET_FILE}"; then
  fail "Report file not found on node01: ${TARGET_FILE}"
fi

if ! ssh ${SSH_OPTS} node01 "test -s ${TARGET_FILE}"; then
  fail "Report file is empty: ${TARGET_FILE}"
fi

line_count="$(ssh ${SSH_OPTS} node01 "wc -l < ${TARGET_FILE}" | tr -d '[:space:]')"
if [ -z "${line_count}" ] || [ "${line_count}" -lt 3 ]; then
  fail "Report file must contain at least 3 detected process events"
fi

if ! ssh ${SSH_OPTS} node01 "awk -F, 'NF!=3{exit 1} $1 !~ /^\[[0-9]{4}-[0-9]{2}-[0-9]{2}T[^][]*Z\]$/{exit 1} $2 !~ /^\[[^][]+\]$/{exit 1} $3 !~ /^\[[^][]+\]$/{exit 1}' ${TARGET_FILE}"; then
  fail "Each line must match format [timestamp],[uid],[processName]"
fi

oldest_epoch="$(ssh ${SSH_OPTS} node01 "head -n 1 ${TARGET_FILE} | cut -d, -f1 | tr -d '[]'" | xargs -I{} date -u -d '{}' +%s 2>/dev/null || true)"
newest_epoch="$(ssh ${SSH_OPTS} node01 "tail -n 1 ${TARGET_FILE} | cut -d, -f1 | tr -d '[]'" | xargs -I{} date -u -d '{}' +%s 2>/dev/null || true)"

if [ -z "${oldest_epoch}" ] || [ -z "${newest_epoch}" ]; then
  fail "Could not parse timestamps from ${TARGET_FILE}"
fi

window="$(( newest_epoch - oldest_epoch ))"
if [ "${window}" -lt 35 ]; then
  fail "Observed event window is too short (${window}s). Monitor for at least 40 seconds."
fi

if ! ssh ${SSH_OPTS} node01 "grep -Eq ',\[(sh|id|uname|date|sleep)\]$' ${TARGET_FILE}"; then
  fail "Expected process names (sh/id/uname/date/sleep) were not detected"
fi

echo "Verification passed"
