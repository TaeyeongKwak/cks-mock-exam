#!/bin/bash
set -euo pipefail

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
TARGET_FILE="/opt/node-01/alerts/details"
RULE_FILE="/etc/falco/falco_rules.local.yaml"

fail() {
  echo "$1" >&2
  exit 1
}

if ! ssh ${SSH_OPTS} node01 "test -f ${RULE_FILE}"; then
  fail "Falco local rules file not found on node01: ${RULE_FILE}"
fi

if ! ssh ${SSH_OPTS} node01 "grep -Eq 'condition:.*execve.*execveat|condition:.*execveat.*execve' ${RULE_FILE}"; then
  fail "Falco rule must match execve or execveat events"
fi

if ! ssh ${SSH_OPTS} node01 "grep -Eq 'condition:.*container\.id[[:space:]]*!=[[:space:]]*host' ${RULE_FILE}"; then
  fail "Falco rule must target container activity"
fi

if ! ssh ${SSH_OPTS} node01 "grep -Eq 'condition:.*evt\.dir=<.*evt\.failed=false|condition:.*evt\.failed=false.*evt\.dir=<' ${RULE_FILE}"; then
  fail "Falco rule should filter for successful process executions"
fi

if ! ssh ${SSH_OPTS} node01 "grep -Eq '%evt.time,%user\.(uid|name),%proc.name' ${RULE_FILE}"; then
  fail "Falco rule output must emit timestamp, uid/username, and process name"
fi

if ! ssh ${SSH_OPTS} node01 "test -f ${TARGET_FILE}"; then
  fail "Incident file not found on node01: ${TARGET_FILE}"
fi

if ! ssh ${SSH_OPTS} node01 "test -s ${TARGET_FILE}"; then
  fail "Incident file is empty: ${TARGET_FILE}"
fi

line_count="$(ssh ${SSH_OPTS} node01 "wc -l < ${TARGET_FILE}" | tr -d '[:space:]')"
if [ -z "${line_count}" ] || [ "${line_count}" -lt 3 ]; then
  fail "Incident file must contain at least 3 detected process events"
fi

if ! ssh ${SSH_OPTS} node01 "awk -F, 'NF!=3{exit 1} $1 !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}T[^,]*Z$/{exit 1} $2==\"\"{exit 1} $3==\"\"{exit 1}' ${TARGET_FILE}"; then
  fail "Each line must match format timestamp,uid/username,processName"
fi

oldest_epoch="$(ssh ${SSH_OPTS} node01 "head -n 1 ${TARGET_FILE} | cut -d, -f1" | xargs -I{} date -u -d '{}' +%s 2>/dev/null || true)"
newest_epoch="$(ssh ${SSH_OPTS} node01 "tail -n 1 ${TARGET_FILE} | cut -d, -f1" | xargs -I{} date -u -d '{}' +%s 2>/dev/null || true)"

if [ -z "${oldest_epoch}" ] || [ -z "${newest_epoch}" ]; then
  fail "Could not parse timestamps from ${TARGET_FILE}"
fi

window="$(( newest_epoch - oldest_epoch ))"
if [ "${window}" -lt 25 ]; then
  fail "Observed event window is too short (${window}s). Monitor for at least 30 seconds."
fi

if ! ssh ${SSH_OPTS} node01 "grep -Eq ',(sh|sleep|true)$' ${TARGET_FILE}"; then
  fail "Expected container process names (sh/sleep/true) were not detected"
fi

echo "Verification passed"
