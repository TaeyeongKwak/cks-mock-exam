#!/bin/bash
set -euo pipefail

WORKDIR="/candidate/14"
OUTPUT_FILE="${WORKDIR}/files.txt"
BIN="${WORKDIR}/ldap-watch"

fail() {
  echo "$1" >&2
  exit 1
}

[ -f "${OUTPUT_FILE}" ] || fail "Open files list not found at ${OUTPUT_FILE}"
[ -s "${OUTPUT_FILE}" ] || fail "Open files list is empty"

grep -Fq "${BIN}" "${OUTPUT_FILE}" || fail "files.txt does not include the executable path ${BIN}"
grep -Eq '(:389|TCP.*389)' "${OUTPUT_FILE}" || fail "files.txt does not show the port 389 listener"

if [ -e "${BIN}" ]; then
  fail "Executable binary ${BIN} still exists"
fi

line_count="$(wc -l < "${OUTPUT_FILE}" | tr -d ' ')"
[ "${line_count}" -ge 3 ] || fail "files.txt does not appear to contain a full open file listing"

echo "Verification passed"
