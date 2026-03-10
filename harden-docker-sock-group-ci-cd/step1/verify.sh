#!/bin/bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get namespace ci-ops >/dev/null 2>&1 || fail "Namespace ci-ops not found"
kubectl get deployment ci-runner -n ci-ops >/dev/null 2>&1 || fail "Deployment ci-runner not found"
kubectl rollout status deployment/ci-runner -n ci-ops --timeout=120s >/dev/null 2>&1 || fail "Deployment ci-runner is not ready"

deploy_json="$(kubectl get deployment ci-runner -n ci-ops -o json)"
DEPLOY_JSON="${deploy_json}" python3 - <<'PY' || exit 1
import json
import os
import sys

data = json.loads(os.environ["DEPLOY_JSON"])
tmpl = data["spec"]["template"]["spec"]

volumes = tmpl.get("volumes", []) or []
if not any(v.get("hostPath", {}).get("path") == "/var/run/docker.sock" for v in volumes):
    print("Deployment no longer references hostPath /var/run/docker.sock", file=sys.stderr)
    sys.exit(1)

containers = tmpl.get("containers", []) or []
if not containers:
    print("Deployment has no containers", file=sys.stderr)
    sys.exit(1)

if not any(
    any(m.get("mountPath") == "/var/run/docker.sock" for m in (c.get("volumeMounts", []) or []))
    for c in containers
):
    print("Deployment no longer mounts /var/run/docker.sock", file=sys.stderr)
    sys.exit(1)

pod_sc = tmpl.get("securityContext", {}) or {}
for field in ("runAsGroup", "fsGroup"):
    if pod_sc.get(field) == 123:
        print(f"Pod securityContext still sets {field} to docker group 123", file=sys.stderr)
        sys.exit(1)

if 123 in (pod_sc.get("supplementalGroups", []) or []):
    print("Pod securityContext still includes supplemental group 123", file=sys.stderr)
    sys.exit(1)

for container in containers:
    csc = container.get("securityContext", {}) or {}
    if csc.get("runAsGroup") == 123:
        print(f"Container {container['name']} still uses docker group 123", file=sys.stderr)
        sys.exit(1)
PY

pod_name="$(kubectl get pods -n ci-ops -l app=ci-runner -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)"
[ -n "${pod_name}" ] || fail "No running Pod found for deployment ci-runner"
kubectl wait --for=condition=Ready "pod/${pod_name}" -n ci-ops --timeout=120s >/dev/null 2>&1 || fail "Pod ${pod_name} is not Ready"

access_check="$(kubectl exec -n ci-ops "${pod_name}" -- sh -c 'if [ -r /var/run/docker.sock ] || [ -w /var/run/docker.sock ]; then echo accessible; else echo blocked; fi' 2>/dev/null || true)"
[ "${access_check}" = "blocked" ] || fail "Pod ${pod_name} can still access /var/run/docker.sock"

echo "Verification passed"
