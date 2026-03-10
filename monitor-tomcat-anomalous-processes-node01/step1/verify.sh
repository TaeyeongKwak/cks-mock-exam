#!/bin/bash
set -euo pipefail

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
OUTPUT_FILE="/home/anomalous/report"

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get pod tomcat >/dev/null 2>&1 || fail "Pod tomcat not found"
kubectl wait --for=condition=Ready pod/tomcat --timeout=120s >/dev/null 2>&1 || fail "Pod tomcat is not Ready"

scheduled_node="$(kubectl get pod tomcat -o jsonpath='{.spec.nodeName}')"
[ "${scheduled_node}" = "node01" ] || fail "Pod tomcat must run on node01"

if ! ssh ${SSH_OPTS} node01 "test -f ${OUTPUT_FILE}"; then
  fail "Incident report not found at node01:${OUTPUT_FILE}"
fi

file_contents="$(ssh ${SSH_OPTS} node01 "cat ${OUTPUT_FILE}" 2>/dev/null || true)"
[ -n "${file_contents}" ] || fail "Incident report is empty"

FILE_CONTENTS="${file_contents}" python3 - <<'PY' || exit 1
import datetime
import os
import re
import sys

lines = [line.strip() for line in os.environ["FILE_CONTENTS"].splitlines() if line.strip()]
if len(lines) < 4:
    print("Incident report must contain at least 4 incidents", file=sys.stderr)
    sys.exit(1)

pattern = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z,\d+,[A-Za-z0-9._-]+$")
timestamps = []
uids = set()
procs = set()
for line in lines:
    if not pattern.match(line):
        print(f"Invalid incident line format: {line}", file=sys.stderr)
        sys.exit(1)
    ts, uid, proc = line.split(",", 2)
    timestamps.append(datetime.datetime.fromisoformat(ts.replace("Z", "+00:00")))
    uids.add(uid)
    procs.add(proc)

span = (max(timestamps) - min(timestamps)).total_seconds()
if span < 40:
    print("Incidents do not span long enough to demonstrate at least 40 seconds of monitoring", file=sys.stderr)
    sys.exit(1)

if "0" not in uids:
    print("Incident report does not include the expected UID 0", file=sys.stderr)
    sys.exit(1)

if len(procs.intersection({"id", "uname", "wget", "sh"})) < 2:
    print("Incident report does not include the expected anomalous process names", file=sys.stderr)
    sys.exit(1)
PY

echo "Verification passed"
