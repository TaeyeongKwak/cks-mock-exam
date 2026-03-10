#!/bin/bash
set -euo pipefail

MANIFEST="/root/kubesec-audit.yaml"
HELPER="/usr/local/bin/kubesec-docker-scan"

fail() {
  echo "$1" >&2
  exit 1
}

[ -f "${MANIFEST}" ] || fail "Manifest not found at ${MANIFEST}"
[ -x "${HELPER}" ] || fail "KubeSec helper not found at ${HELPER}"

kubectl apply --dry-run=client -f "${MANIFEST}" >/dev/null 2>&1 || fail "Manifest is not valid Kubernetes YAML"

scan_output="$("${HELPER}" "${MANIFEST}" 2>/dev/null || true)"
[ -n "${scan_output}" ] || fail "KubeSec scan produced no output"

SCAN_OUTPUT="${scan_output}" python3 - <<'PY' || exit 1
import json
import os
import sys

raw = os.environ["SCAN_OUTPUT"]
try:
    data = json.loads(raw)
except json.JSONDecodeError:
    print("KubeSec output is not valid JSON", file=sys.stderr)
    sys.exit(1)

if not isinstance(data, list) or not data:
    print("KubeSec output does not contain scan results", file=sys.stderr)
    sys.exit(1)

result = data[0]
score = result.get("score")
if score is None:
    print("KubeSec output does not include a score", file=sys.stderr)
    sys.exit(1)
if score < 4:
    print(f"KubeSec score is {score}, but it must be at least 4", file=sys.stderr)
    sys.exit(1)
if result.get("valid") is not True:
    print("Manifest is not considered valid by KubeSec", file=sys.stderr)
    sys.exit(1)
PY

manifest_json="$(kubectl create --dry-run=client -f "${MANIFEST}" -o json 2>/dev/null)"
MANIFEST_JSON="${manifest_json}" python3 - <<'PY' || exit 1
import json
import os
import sys

data = json.loads(os.environ["MANIFEST_JSON"])
spec = data.get("spec", {})
pod_sc = spec.get("securityContext", {})
containers = spec.get("containers", [])
if not containers:
    print("Manifest must contain at least one container", file=sys.stderr)
    sys.exit(1)

container = containers[0]
sc = container.get("securityContext", {})

if spec.get("automountServiceAccountToken") is not False:
    print("automountServiceAccountToken should be false", file=sys.stderr)
    sys.exit(1)
if sc.get("allowPrivilegeEscalation") is not False:
    print("allowPrivilegeEscalation should be false", file=sys.stderr)
    sys.exit(1)
if sc.get("readOnlyRootFilesystem") is not True:
    print("readOnlyRootFilesystem should be true", file=sys.stderr)
    sys.exit(1)
if sc.get("runAsNonRoot") is not True and pod_sc.get("runAsNonRoot") is not True:
    print("runAsNonRoot should be true at pod or container level", file=sys.stderr)
    sys.exit(1)
caps = sc.get("capabilities", {})
drop = caps.get("drop") or []
if "ALL" not in drop:
    print("Container should drop ALL capabilities", file=sys.stderr)
    sys.exit(1)
PY

echo "Verification passed"
