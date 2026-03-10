#!/bin/bash
set -euo pipefail

MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"
POLICY="/etc/kubernetes/pki/ops-audit-rules.yaml"
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

grep -q -- '--audit-policy-file=/etc/kubernetes/pki/ops-audit-rules.yaml' "${MANIFEST}" || fail "Static Pod manifest does not point to ops-audit-rules.yaml"
grep -q -- '--audit-log-path=/var/log/kubernetes-logs.log' "${MANIFEST}" || fail "Static Pod manifest must log to /var/log/kubernetes-logs.log"
grep -q -- '--audit-log-maxage=5' "${MANIFEST}" || fail "Static Pod manifest must keep logs for 5 days"
grep -q -- '--audit-log-maxbackup=10' "${MANIFEST}" || fail "Static Pod manifest must keep 10 backups"
grep -q -- '--audit-log-maxsize=100' "${MANIFEST}" || fail "Static Pod manifest must rotate at 100 MB"

container_id="$(crictl ps --name kube-apiserver -q | head -n 1 | tr -d '\r')"
[ -n "${container_id}" ] || fail "Running kube-apiserver container not found"

inspect_output="$(crictl inspect "${container_id}" 2>/dev/null || true)"
echo "${inspect_output}" | grep -q -- '--audit-policy-file=/etc/kubernetes/pki/ops-audit-rules.yaml' || fail "Running kube-apiserver is not using the required audit policy path"
echo "${inspect_output}" | grep -q -- '--audit-log-path=/var/log/kubernetes-logs.log' || fail "Running kube-apiserver is not using the required audit log path"
echo "${inspect_output}" | grep -q -- '--audit-log-maxage=5' || fail "Running kube-apiserver is not using audit-log-maxage=5"
echo "${inspect_output}" | grep -q -- '--audit-log-maxbackup=10' || fail "Running kube-apiserver is not using audit-log-maxbackup=10"
echo "${inspect_output}" | grep -q -- '--audit-log-maxsize=100' || fail "Running kube-apiserver is not using audit-log-maxsize=100"

python - "$POLICY" <<'PY'
import sys
from pathlib import Path

policy_path = Path(sys.argv[1])
text = policy_path.read_text()

if "apiVersion: audit.k8s.io/v1" not in text or "kind: Policy" not in text:
    raise SystemExit("Audit policy header is invalid")

if "/livez*" not in text or "/readyz*" not in text:
    raise SystemExit("Seed probe exclusions were not preserved")

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

cron = find("RequestResponse", 'group: "batch"', "cronjobs")
deploy = find("Request", 'group: "apps"', "deployments", "kube-system")
if deploy is None:
    deploy = find("RequestResponse", 'group: "apps"', "deployments", "kube-system")
catch_all = find("Request", 'group: ""', 'group: "extensions"')
exclude = find("None", "system:kube-proxy", "watch", "endpoints", "services", 'group: ""')

if cron is None:
    raise SystemExit("CronJob RequestResponse rule not found")
if deploy is None:
    raise SystemExit("kube-system Deployment body logging rule not found")
if catch_all is None:
    raise SystemExit("core/extensions Request rule not found")
if exclude is None:
    raise SystemExit("kube-proxy exclusion rule not found")
if exclude > catch_all:
    raise SystemExit("kube-proxy exclusion must appear before the broad Request rule")
PY

kubectl --kubeconfig="${KUBECONFIG}" get nodes >/dev/null 2>&1 || fail "Authenticated kubectl check failed"

echo "Verification passed"
