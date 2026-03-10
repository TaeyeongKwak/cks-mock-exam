#!/bin/bash
set -euo pipefail

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
OUTPUT_FILE="/opt/node-01/reports/events"

fail() {
  echo "$1" >&2
  exit 1
}

if ! ssh ${SSH_OPTS} node01 "test -f ${OUTPUT_FILE}"; then
  fail "Incident file not found at node01:${OUTPUT_FILE}"
fi

file_contents="$(ssh ${SSH_OPTS} node01 "cat ${OUTPUT_FILE}" 2>/dev/null || true)"
[ -n "${file_contents}" ] || fail "Incident file is empty"

FILE_CONTENTS="${file_contents}" python3 - <<'PY' || exit 1
import datetime
import os
import re
import sys

lines = [line.strip() for line in os.environ["FILE_CONTENTS"].splitlines() if line.strip()]
if len(lines) < 3:
    print("Incident file must contain at least 3 incidents", file=sys.stderr)
    sys.exit(1)

pattern = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z,[^,]+,[A-Za-z0-9._-]+$")
timestamps = []
users = set()
procs = set()
for line in lines:
    if not pattern.match(line):
        print(f"Invalid incident line format: {line}", file=sys.stderr)
        sys.exit(1)
    ts, user, proc = line.split(",", 2)
    timestamps.append(datetime.datetime.fromisoformat(ts.replace("Z", "+00:00")))
    users.add(user)
    procs.add(proc)

span = (max(timestamps) - min(timestamps)).total_seconds()
if span < 25:
    print("Incidents do not span long enough to demonstrate at least 30 seconds of monitoring", file=sys.stderr)
    sys.exit(1)

if not users.intersection({"root", "1001", "1002"}):
    print("Incident file does not include expected staged users", file=sys.stderr)
    sys.exit(1)

if not procs.intersection({"sh", "sleep", "wget"}):
    print("Incident file does not include expected staged process names", file=sys.stderr)
    sys.exit(1)
PY

for deploy in root-spawner uid1001-spawner uid1002-spawner; do
  kubectl rollout status "deployment/${deploy}" -n proc-watch --timeout=120s >/dev/null 2>&1 || fail "Deployment ${deploy} is not ready"
done

echo "Verification passed"
