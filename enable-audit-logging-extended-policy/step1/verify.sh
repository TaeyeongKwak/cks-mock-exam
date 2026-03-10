#!/bin/bash
set -euo pipefail

MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"
POLICY="/etc/kubernetes/pki/forensics-audit.yaml"
KUBECONFIG="/etc/kubernetes/admin.conf"

fail() {
  echo "$1" >&2
  exit 1
}

wait_api() {
  for _ in $(seq 1 90); do
    if kubectl --kubeconfig="${KUBECONFIG}" get --raw /readyz >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  return 1
}

wait_api || fail "API server is not ready"
[ -f "${POLICY}" ] || fail "Audit policy file not found at ${POLICY}"

grep -q -- '--audit-policy-file=/etc/kubernetes/pki/forensics-audit.yaml' "${MANIFEST}" || fail "Static Pod manifest does not point to forensics-audit.yaml"
grep -q -- '--audit-log-path=/var/log/kubernetes-logs.log' "${MANIFEST}" || fail "Static Pod manifest must log to /var/log/kubernetes-logs.log"
grep -q -- '--audit-log-maxage=12' "${MANIFEST}" || fail "Static Pod manifest must keep logs for 12 days"
grep -q -- '--audit-log-maxbackup=8' "${MANIFEST}" || fail "Static Pod manifest must keep 8 backups"
grep -q -- '--audit-log-maxsize=200' "${MANIFEST}" || fail "Static Pod manifest must rotate at 200 MB"

container_id="$(crictl ps --name kube-apiserver -q | head -n 1 | tr -d '\r')"
[ -n "${container_id}" ] || fail "Running kube-apiserver container not found"

inspect_output="$(crictl inspect "${container_id}" 2>/dev/null || true)"
echo "${inspect_output}" | grep -q -- '--audit-policy-file=/etc/kubernetes/pki/forensics-audit.yaml' || fail "Running kube-apiserver is not using the required audit policy path"
echo "${inspect_output}" | grep -q -- '--audit-log-path=/var/log/kubernetes-logs.log' || fail "Running kube-apiserver is not using the required audit log path"
echo "${inspect_output}" | grep -q -- '--audit-log-maxage=12' || fail "Running kube-apiserver is not using audit-log-maxage=12"
echo "${inspect_output}" | grep -q -- '--audit-log-maxbackup=8' || fail "Running kube-apiserver is not using audit-log-maxbackup=8"
echo "${inspect_output}" | grep -q -- '--audit-log-maxsize=200' || fail "Running kube-apiserver is not using audit-log-maxsize=200"

python - "$POLICY" <<'PY'
import sys
from pathlib import Path

policy_path = Path(sys.argv[1])
text = policy_path.read_text()

if "apiVersion: audit.k8s.io/v1" not in text or "kind: Policy" not in text:
    raise SystemExit("Audit policy header is invalid")

if "omitStages:" not in text or "RequestReceived" not in text:
    raise SystemExit("RequestReceived must be omitted")

if "/healthz*" not in text:
    raise SystemExit("Seed health check exclusion was not preserved")

lines = text.splitlines()
blocks = []
current = []
for line in lines:
    stripped = line.lstrip()
    if stripped.startswith("- level:"):
        if current:
            blocks.append("\n".join(current))
        current = [line]
    elif current:
        current.append(line)
if current:
    blocks.append("\n".join(current))

def find(level, *needles):
    for idx, block in enumerate(blocks):
        if f"level: {level}" not in block:
            continue
        if all(needle in block for needle in needles):
            return idx
    return None

def is_default_metadata(block):
    return (
        "level: Metadata" in block and
        "resources:" not in block and
        "users:" not in block and
        "userGroups:" not in block and
        "verbs:" not in block and
        "namespaces:" not in block and
        "nonResourceURLs:" not in block
    )

namespace_rule = find("RequestResponse", 'group: ""', "namespaces")
secret_rule = find("Request", 'group: ""', "secrets", "kube-system")
subresource_rule = find("Metadata", 'group: ""', "pods/portforward", "services/proxy")
core_ext_rule = find("Request", 'group: ""', 'group: "extensions"')
default_rule = None
for idx, block in enumerate(blocks):
    if is_default_metadata(block):
        default_rule = idx

if namespace_rule is None:
    raise SystemExit("Namespace RequestResponse rule not found")
if secret_rule is None:
    raise SystemExit("kube-system Secret Request rule not found")
if subresource_rule is None:
    raise SystemExit("Subresource Metadata rule not found")
if core_ext_rule is None:
    raise SystemExit("core/extensions Request rule not found")
if default_rule is None:
    raise SystemExit("Trailing default Metadata rule not found")
if namespace_rule > core_ext_rule:
    raise SystemExit("Namespace rule must appear before the broad Request rule")
if secret_rule > core_ext_rule:
    raise SystemExit("Secret rule must appear before the broad Request rule")
if subresource_rule > core_ext_rule:
    raise SystemExit("Subresource Metadata rule must appear before the broad Request rule")
if default_rule < core_ext_rule:
    raise SystemExit("Default Metadata rule must be last")
PY

kubectl --kubeconfig="${KUBECONFIG}" get nodes >/dev/null 2>&1 || fail "Authenticated kubectl check failed"

echo "Verification passed"
