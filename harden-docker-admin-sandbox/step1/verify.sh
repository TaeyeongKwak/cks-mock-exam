#!/bin/bash
set -euo pipefail

MANIFEST="/root/sandbox/docker-ops.yaml"

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get namespace sandbox-lab >/dev/null 2>&1 || fail "Namespace sandbox-lab not found"
[ -f "${MANIFEST}" ] || fail "Manifest not found at ${MANIFEST}"

kubectl apply --dry-run=server -f "${MANIFEST}" >/dev/null 2>&1 || fail "Manifest is still rejected by server-side validation"

kubectl get deployment docker-ops -n sandbox-lab >/dev/null 2>&1 || fail "Deployment docker-ops not found in sandbox-lab"
kubectl rollout status deployment/docker-ops -n sandbox-lab --timeout=180s >/dev/null 2>&1 || fail "Deployment docker-ops is not ready"

deploy_json="$(kubectl get deployment docker-ops -n sandbox-lab -o json)"
DEPLOY_JSON="${deploy_json}" python3 - <<'PY' || exit 1
import json
import os
import sys

data = json.loads(os.environ["DEPLOY_JSON"])
spec = data["spec"]["template"]["spec"]
containers = spec.get("containers", [])
volumes = spec.get("volumes", [])

if len(containers) != 1:
    print("Deployment must define exactly one container", file=sys.stderr)
    sys.exit(1)

container = containers[0]
sc = container.get("securityContext", {})

mount_ok = any(m.get("mountPath") == "/var/run/docker.sock" for m in container.get("volumeMounts", []) or [])
if not mount_ok:
    print("Container must keep the /var/run/docker.sock mount", file=sys.stderr)
    sys.exit(1)

volume_ok = False
for volume in volumes:
    hp = volume.get("hostPath")
    if hp and hp.get("path") == "/var/run/docker.sock":
        volume_ok = True
        break
if not volume_ok:
    print("Deployment must keep the hostPath volume for /var/run/docker.sock", file=sys.stderr)
    sys.exit(1)

if sc.get("runAsNonRoot") is not True:
    print("Container securityContext.runAsNonRoot must be true", file=sys.stderr)
    sys.exit(1)

run_as_user = sc.get("runAsUser")
if run_as_user in (None, 0):
    print("Container must run as a non-root UID", file=sys.stderr)
    sys.exit(1)

caps = sc.get("capabilities", {})
drop = caps.get("drop") or []
if "ALL" not in drop:
    print("Container must drop ALL capabilities", file=sys.stderr)
    sys.exit(1)

adds = caps.get("add") or []
if adds:
    print("Container must not add extra capabilities for this scenario", file=sys.stderr)
    sys.exit(1)

if sc.get("readOnlyRootFilesystem") is not True:
    print("Container must enable readOnlyRootFilesystem", file=sys.stderr)
    sys.exit(1)
PY

pod_name="$(kubectl get pods -n sandbox-lab -l app=docker-ops -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)"
[ -n "${pod_name}" ] || fail "No running Pod found for docker-ops"
kubectl wait --for=condition=Ready "pod/${pod_name}" -n sandbox-lab --timeout=120s >/dev/null 2>&1 || fail "Pod ${pod_name} is not Ready"

echo "Verification passed"
