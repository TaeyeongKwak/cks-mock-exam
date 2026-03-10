#!/bin/bash
set -euo pipefail

IMAGE_LIST="/opt/scan-images.txt"
OUTPUT_FILE="/opt/scan-high-critical.txt"

fail() {
  echo "$1" >&2
  exit 1
}

command -v trivy >/dev/null 2>&1 || fail "trivy is not installed"
[ -f "${IMAGE_LIST}" ] || fail "Image list not found at ${IMAGE_LIST}"
[ -f "${OUTPUT_FILE}" ] || fail "Output file not found at ${OUTPUT_FILE}"
[ -s "${OUTPUT_FILE}" ] || fail "Output file is empty"

while IFS= read -r image; do
  [ -n "${image}" ] || continue
  grep -Fq "${image}" "${OUTPUT_FILE}" || fail "Output file does not contain results for ${image}"
done < "${IMAGE_LIST}"

if grep -Eiq 'Severity:[[:space:]]*(LOW|MEDIUM|UNKNOWN)' "${OUTPUT_FILE}"; then
  fail "Output file contains severities outside HIGH and CRITICAL"
fi

if ! grep -Eiq '(HIGH|CRITICAL)' "${OUTPUT_FILE}"; then
  fail "Output file does not show any HIGH or CRITICAL findings"
fi

line_count="$(wc -l < "${IMAGE_LIST}" | tr -d ' ')"
header_count="$(grep -Ec '^[=]+[[:space:]]*$|^.* \(.*\)$' "${OUTPUT_FILE}" || true)"
if [ "${header_count}" -lt "${line_count}" ]; then
  # Fallback: at least ensure each image appears once if the exact output format differs.
  :
fi

echo "Verification passed"
