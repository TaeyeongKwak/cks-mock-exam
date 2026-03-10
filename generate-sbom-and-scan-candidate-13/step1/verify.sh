#!/bin/bash
set -euo pipefail

CANDIDATE_DIR="/opt/candidate/13a"
SBOM1="${CANDIDATE_DIR}/sbom1.json"
SBOM2="${CANDIDATE_DIR}/sbom2.json"
SBOM_CHECK="${CANDIDATE_DIR}/sbom_check.json"
SBOM_RESULT="${CANDIDATE_DIR}/sbom_result.json"
EXPECTED_SCAN="${CANDIDATE_DIR}/.expected-sbom-result.json"
EXPECTED_VULNS="${CANDIDATE_DIR}/.expected-vuln-ids.txt"

fail() {
  echo "$1" >&2
  exit 1
}

command -v bom >/dev/null 2>&1 || fail "bom is not installed"
command -v trivy >/dev/null 2>&1 || fail "trivy is not installed"
[ -f "${SBOM_CHECK}" ] || fail "Staged SBOM not found at ${SBOM_CHECK}"
[ -f "${EXPECTED_SCAN}" ] || fail "Expected scan reference not found"
[ -f "${EXPECTED_VULNS}" ] || fail "Expected vulnerability list not found"
[ -f "${SBOM1}" ] || fail "File not found: ${SBOM1}"
[ -f "${SBOM2}" ] || fail "File not found: ${SBOM2}"
[ -f "${SBOM_RESULT}" ] || fail "File not found: ${SBOM_RESULT}"
[ -s "${SBOM1}" ] || fail "SBOM file is empty: ${SBOM1}"
[ -s "${SBOM2}" ] || fail "SBOM file is empty: ${SBOM2}"
[ -s "${SBOM_RESULT}" ] || fail "Scan result file is empty: ${SBOM_RESULT}"

SBOM1_PATH="${SBOM1}" SBOM2_PATH="${SBOM2}" SBOM_RESULT_PATH="${SBOM_RESULT}" EXPECTED_VULNS_PATH="${EXPECTED_VULNS}" python3 - <<'PY' || exit 1
import json
import os
import sys

def fail(msg: str) -> None:
    print(msg, file=sys.stderr)
    sys.exit(1)

with open(os.environ["SBOM1_PATH"], "r", encoding="utf-8") as fh:
    sbom1 = json.load(fh)
with open(os.environ["SBOM2_PATH"], "r", encoding="utf-8") as fh:
    sbom2 = json.load(fh)
with open(os.environ["SBOM_RESULT_PATH"], "r", encoding="utf-8") as fh:
    result = json.load(fh)
with open(os.environ["EXPECTED_VULNS_PATH"], "r", encoding="utf-8") as fh:
    expected_vulns = sorted(line.strip() for line in fh if line.strip())

if not isinstance(sbom1, dict):
    fail("sbom1.json must be a JSON object")
if sbom1.get("spdxVersion", "").upper().startswith("SPDX-") is False:
    fail("sbom1.json must be an SPDX-JSON document")
sbom1_text = json.dumps(sbom1)
if "registry.k8s.io/kube-apiserver:v1.32.0" not in sbom1_text:
    fail("sbom1.json does not describe registry.k8s.io/kube-apiserver:v1.32.0")

if not isinstance(sbom2, dict):
    fail("sbom2.json must be a JSON object")
if sbom2.get("bomFormat") != "CycloneDX":
    fail("sbom2.json must be a CycloneDX document")
sbom2_text = json.dumps(sbom2)
if "registry.k8s.io/kube-controller-manager:v1.32.0" not in sbom2_text:
    fail("sbom2.json does not describe registry.k8s.io/kube-controller-manager:v1.32.0")

if not isinstance(result, dict):
    fail("sbom_result.json must be a JSON object")
if "Results" not in result:
    fail("sbom_result.json must contain Trivy Results")

actual_vulns = sorted(
    {
        vuln["VulnerabilityID"]
        for res in result.get("Results", []) or []
        for vuln in (res.get("Vulnerabilities") or [])
        if vuln.get("VulnerabilityID")
    }
)

if actual_vulns != expected_vulns:
    fail("sbom_result.json does not match the expected vulnerability scan result for sbom_check.json")
PY

echo "Verification passed"
