#!/bin/bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get namespace build-ops >/dev/null 2>&1 || fail "Namespace build-ops not found"

for deploy in job-runner image-scan api-gateway; do
  kubectl get deployment "${deploy}" -n build-ops >/dev/null 2>&1 || fail "Deployment ${deploy} not found"
  kubectl rollout status "deployment/${deploy}" -n build-ops --timeout=120s >/dev/null 2>&1 || fail "Deployment ${deploy} is not ready"
done

for deploy in job-runner image-scan; do
  deploy_json="$(kubectl get deployment "${deploy}" -n build-ops -o json)"
  DEPLOY_JSON="${deploy_json}" python3 - <<'PY' || exit 1
import json
import os
import sys

data = json.loads(os.environ["DEPLOY_JSON"])
tmpl = data["spec"]["template"]["spec"]
for container in tmpl.get("containers", []):
    for mount in container.get("volumeMounts", []) or []:
        if mount.get("mountPath") == "/var/run/docker.sock":
            print(f"Deployment {data['metadata']['name']} still mounts /var/run/docker.sock", file=sys.stderr)
            sys.exit(1)
for volume in tmpl.get("volumes", []) or []:
    hp = volume.get("hostPath")
    if hp and hp.get("path") == "/var/run/docker.sock":
        print(f"Deployment {data['metadata']['name']} still references hostPath /var/run/docker.sock", file=sys.stderr)
        sys.exit(1)
PY
done

for deploy in job-runner image-scan api-gateway; do
  pod_name="$(kubectl get pods -n build-ops -l app=${deploy} -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)"
  [ -n "${pod_name}" ] || fail "No running Pod found for Deployment ${deploy}"
  kubectl wait --for=condition=Ready "pod/${pod_name}" -n build-ops --timeout=120s >/dev/null 2>&1 || fail "Pod ${pod_name} is not Ready"

  access_check="$(kubectl exec -n build-ops "${pod_name}" -- sh -c 'if [ -e /var/run/docker.sock ]; then echo present; else echo absent; fi' 2>/dev/null || true)"
  [ "${access_check}" = "absent" ] || fail "Pod ${pod_name} can still access /var/run/docker.sock"
done

safe_json="$(kubectl get deployment api-gateway -n build-ops -o json)"
SAFE_JSON="${safe_json}" python3 - <<'PY' || exit 1
import json
import os
import sys

data = json.loads(os.environ["SAFE_JSON"])
for container in data["spec"]["template"]["spec"].get("containers", []):
    for mount in container.get("volumeMounts", []) or []:
        if mount.get("mountPath") == "/var/run/docker.sock":
            print("api-gateway should not mount /var/run/docker.sock", file=sys.stderr)
            sys.exit(1)
PY

echo "Verification passed"
