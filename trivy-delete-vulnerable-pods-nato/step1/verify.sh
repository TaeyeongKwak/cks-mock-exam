#!/bin/bash
set -euo pipefail

REPORT_FILE="/opt/atlas-trivy-report.txt"
POD_IMAGE_FILE="/opt/atlas-pod-images.txt"
EXPECTED_BAD="/opt/.atlas-expected-severe-pods.txt"
EXPECTED_GOOD="/opt/.atlas-expected-safe-pods.txt"

fail() {
  echo "$1" >&2
  exit 1
}

command -v trivy >/dev/null 2>&1 || fail "trivy is not installed"
kubectl get namespace atlas >/dev/null 2>&1 || fail "Namespace atlas not found"
[ -f "${POD_IMAGE_FILE}" ] || fail "Pod image mapping not found at ${POD_IMAGE_FILE}"
[ -f "${REPORT_FILE}" ] || fail "Report file not found at ${REPORT_FILE}"
[ -s "${REPORT_FILE}" ] || fail "Report file is empty"
[ -f "${EXPECTED_BAD}" ] || fail "Expected vulnerable pod list missing"
[ -f "${EXPECTED_GOOD}" ] || fail "Expected safe pod list missing"

while read -r pod image; do
  [ -n "${pod:-}" ] || continue
  grep -Fq "${image}" "${REPORT_FILE}" || fail "Report file does not contain results for ${image}"
done < "${POD_IMAGE_FILE}"

if grep -Eiq 'Severity:[[:space:]]*(LOW|MEDIUM|UNKNOWN)' "${REPORT_FILE}"; then
  fail "Report file contains severities outside HIGH and CRITICAL"
fi

if ! grep -Eiq '(HIGH|CRITICAL)' "${REPORT_FILE}"; then
  fail "Report file does not show any HIGH or CRITICAL findings"
fi

while read -r pod; do
  [ -n "${pod:-}" ] || continue
  if kubectl get pod "${pod}" -n atlas >/dev/null 2>&1; then
    fail "Severely vulnerable Pod ${pod} still exists"
  fi
done < "${EXPECTED_BAD}"

safe_count=0
while read -r pod; do
  [ -n "${pod:-}" ] || continue
  safe_count=$((safe_count + 1))
  kubectl get pod "${pod}" -n atlas >/dev/null 2>&1 || fail "Non-vulnerable Pod ${pod} should remain"
  kubectl wait --for=condition=Ready "pod/${pod}" -n atlas --timeout=120s >/dev/null 2>&1 || fail "Remaining Pod ${pod} is not Ready"
done < "${EXPECTED_GOOD}"

if [ "${safe_count}" -gt 0 ]; then
  remaining_pods="$(kubectl get pods -n atlas --no-headers 2>/dev/null | awk '{print $1}' | sort | tr -d '\r')"
  expected_remaining="$(grep -v '^[[:space:]]*$' "${EXPECTED_GOOD}" | sort | tr -d '\r')"
  [ "${remaining_pods}" = "${expected_remaining}" ] || fail "Namespace atlas contains an unexpected set of remaining Pods"
fi

echo "Verification passed"
