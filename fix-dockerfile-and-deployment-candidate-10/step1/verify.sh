#!/bin/bash
set -euo pipefail

TARGET_DIR="/home/candidate/10-sec"
DOCKERFILE="${TARGET_DIR}/Dockerfile"
DEPLOYMENT="${TARGET_DIR}/deployment.yaml"
REF_DIR="/opt/candidate-10-sec-reference"
REF_DOCKERFILE="${REF_DIR}/Dockerfile"
REF_DEPLOYMENT="${REF_DIR}/deployment.yaml"

fail() {
  echo "$1" >&2
  exit 1
}

[ -f "${DOCKERFILE}" ] || fail "Dockerfile not found at ${DOCKERFILE}"
[ -f "${DEPLOYMENT}" ] || fail "Deployment manifest not found at ${DEPLOYMENT}"
[ -f "${REF_DOCKERFILE}" ] || fail "Reference Dockerfile not found"
[ -f "${REF_DEPLOYMENT}" ] || fail "Reference Deployment manifest not found"

python3 - "${DOCKERFILE}" "${REF_DOCKERFILE}" <<'PY' || exit 1
import sys
from pathlib import Path

current_path = Path(sys.argv[1])
reference_path = Path(sys.argv[2])

def instructions(path):
    items = []
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if raw[:1].isspace():
            continue
        items.append(line.split(None, 1)[0].upper())
    return items

current = instructions(current_path)
reference = instructions(reference_path)
if current != reference:
    print("Dockerfile must not add, remove, or reorder instructions", file=sys.stderr)
    sys.exit(1)
PY

from_line="$(grep -E '^[[:space:]]*FROM[[:space:]]+' "${DOCKERFILE}" | head -n 1 | tr -d '\r')"
[ -n "${from_line}" ] || fail "Dockerfile must contain a FROM line"
echo "${from_line}" | grep -Eq '^FROM[[:space:]]+ubuntu:16\.04([[:space:]]|$)' || fail "Dockerfile must pin the base image to ubuntu:16.04"

last_user_line="$(grep -E '^[[:space:]]*USER[[:space:]]+' "${DOCKERFILE}" | tail -n 1 | tr -d '\r')"
[ -n "${last_user_line}" ] || fail "Dockerfile must contain a runtime USER line"
echo "${last_user_line}" | grep -Eq '^USER[[:space:]]+65535$' || fail "Dockerfile runtime user must be UID 65535"

kubectl apply --dry-run=client -f "${DEPLOYMENT}" >/dev/null 2>&1 || fail "Deployment manifest is not valid YAML for kubectl"

current_json="$(kubectl create --dry-run=client -f "${DEPLOYMENT}" -o json 2>/dev/null)"
reference_json="$(kubectl create --dry-run=client -f "${REF_DEPLOYMENT}" -o json 2>/dev/null)"

CURRENT_JSON="${current_json}" REFERENCE_JSON="${reference_json}" python3 - <<'PY' || exit 1
import json
import os
import sys

current = json.loads(os.environ["CURRENT_JSON"])
reference = json.loads(os.environ["REFERENCE_JSON"])

allowed_value_only = {
    "spec.template.spec.containers[0].image",
    "spec.template.spec.containers[0].securityContext.runAsUser",
}

def collect_leaf_paths(obj, prefix=""):
    paths = set()
    if isinstance(obj, dict):
        for key, value in obj.items():
            child = f"{prefix}.{key}" if prefix else key
            paths |= collect_leaf_paths(value, child)
    elif isinstance(obj, list):
        for idx, value in enumerate(obj):
            child = f"{prefix}[{idx}]"
            paths |= collect_leaf_paths(value, child)
    else:
        paths.add(prefix)
    return paths

cur_paths = collect_leaf_paths(current)
ref_paths = collect_leaf_paths(reference)
if cur_paths != ref_paths:
    print("Deployment manifest must not add or remove settings", file=sys.stderr)
    sys.exit(1)

def get_value(obj, path):
    cur = obj
    for part in path.split("."):
        if "[" in part:
            name, index = part[:-1].split("[", 1)
            cur = cur[name][int(index)]
        else:
            cur = cur[part]
    return cur

for path in sorted(ref_paths):
    if path in allowed_value_only:
        continue
    if path.endswith("metadata.creationTimestamp"):
        continue
    if get_value(current, path) != get_value(reference, path):
        print(f"Only the targeted Deployment values may change: unexpected change at {path}", file=sys.stderr)
        sys.exit(1)
PY

deploy_name="$(kubectl create --dry-run=client -f "${DEPLOYMENT}" -o jsonpath='{.metadata.name}' 2>/dev/null)"
[ "${deploy_name}" = "mysql-audit" ] || fail "Deployment name must remain mysql-audit"

image_name="$(kubectl create --dry-run=client -f "${DEPLOYMENT}" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)"
[ "${image_name}" = "mysql:8.0" ] || fail "Container image must be mysql:8.0"

run_as_user="$(kubectl create --dry-run=client -f "${DEPLOYMENT}" -o jsonpath='{.spec.template.spec.containers[0].securityContext.runAsUser}' 2>/dev/null)"
[ "${run_as_user}" = "65535" ] || fail "Container securityContext.runAsUser must be 65535"

privileged_value="$(kubectl create --dry-run=client -f "${DEPLOYMENT}" -o jsonpath='{.spec.template.spec.containers[0].securityContext.privileged}' 2>/dev/null)"
[ "${privileged_value}" = "false" ] || fail "Container securityContext.privileged must remain false"

ro_value="$(kubectl create --dry-run=client -f "${DEPLOYMENT}" -o jsonpath='{.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem}' 2>/dev/null)"
[ "${ro_value}" = "true" ] || fail "Container securityContext.readOnlyRootFilesystem must remain true"

echo "Verification passed"
