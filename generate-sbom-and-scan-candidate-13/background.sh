#!/bin/bash
set -euo pipefail

TRIVY_VERSION="0.57.1"
TMP_DIR="$(mktemp -d)"
CANDIDATE_DIR="/opt/candidate/13a"

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

install_trivy() {
  if command -v trivy >/dev/null 2>&1; then
    return 0
  fi
  export DEBIAN_FRONTEND=noninteractive
  apt-get update >/dev/null
  apt-get install -y wget gnupg lsb-release apt-transport-https >/dev/null

  wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
    | gpg --dearmor -o /usr/share/keyrings/trivy.gpg

  echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" \
    >/etc/apt/sources.list.d/trivy.list

  apt-get update >/dev/null
  apt-get install -y "trivy=${TRIVY_VERSION}" >/dev/null || apt-get install -y trivy >/dev/null

  command -v trivy >/dev/null 2>&1 || {
    echo "trivy installation failed" >&2
    exit 1
  }
}

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

install_trivy
mkdir -p "${CANDIDATE_DIR}"

cat >/usr/local/bin/bom <<'EOF'
#!/bin/bash
set -euo pipefail

usage() {
  echo "Usage: bom generate --format <spdx-json|cyclonedx> --output <file> <image>" >&2
  exit 1
}

[ "${1:-}" = "generate" ] || usage
shift

format=""
output=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --format)
      format="${2:-}"
      shift 2
      ;;
    --output|-o)
      output="${2:-}"
      shift 2
      ;;
    *)
      image="$1"
      shift
      ;;
  esac
done

[ -n "${format}" ] || usage
[ -n "${output}" ] || usage
[ -n "${image:-}" ] || usage

case "${format}" in
  spdx-json|cyclonedx) ;;
  *) usage ;;
esac

exec trivy image --format "${format}" --output "${output}" "${image}"
EOF
chmod +x /usr/local/bin/bom

trivy image --format spdx-json --output "${CANDIDATE_DIR}/sbom_check.json" httpd:2.4.49 >/dev/null
trivy sbom --format json --output "${CANDIDATE_DIR}/.expected-sbom-result.json" "${CANDIDATE_DIR}/sbom_check.json" >/dev/null

EXPECTED_SCAN="${CANDIDATE_DIR}/.expected-sbom-result.json" python3 - <<'PY'
import json
import os

with open(os.environ["EXPECTED_SCAN"], "r", encoding="utf-8") as fh:
    data = json.load(fh)

vulns = sorted(
    {
        vuln["VulnerabilityID"]
        for result in data.get("Results", []) or []
        for vuln in (result.get("Vulnerabilities") or [])
        if vuln.get("VulnerabilityID")
    }
)

with open("/opt/candidate/13a/.expected-vuln-ids.txt", "w", encoding="utf-8") as fh:
    for vuln_id in vulns:
        fh.write(f"{vuln_id}\n")
PY

rm -f "${CANDIDATE_DIR}/sbom1.json" "${CANDIDATE_DIR}/sbom2.json" "${CANDIDATE_DIR}/sbom_result.json"
