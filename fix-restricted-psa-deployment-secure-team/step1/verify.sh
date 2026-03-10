#!/bin/bash
set -euo pipefail

MANIFEST="/root/masters/restricted-fix.yaml"

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get namespace secure-lab >/dev/null 2>&1 || fail "Namespace secure-lab not found"

enforce_label="$(kubectl get namespace secure-lab -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}')"
[ "${enforce_label}" = "restricted" ] || fail "Namespace secure-lab must enforce the restricted policy"

[ -f "${MANIFEST}" ] || fail "Manifest not found at ${MANIFEST}"
kubectl apply --dry-run=server -f "${MANIFEST}" >/dev/null 2>&1 || fail "Manifest is still rejected by server-side validation"

kubectl get deployment policy-app -n secure-lab >/dev/null 2>&1 || fail "Deployment policy-app not found in secure-lab"
kubectl rollout status deployment/policy-app -n secure-lab --timeout=180s >/dev/null 2>&1 || fail "Deployment policy-app is not ready"

deploy_json="$(kubectl get deployment policy-app -n secure-lab -o json)"
DEPLOY_JSON="${deploy_json}" python3 - <<'PY' || exit 1
import json
import os
import sys

data = json.loads(os.environ["DEPLOY_JSON"])
spec = data["spec"]["template"]["spec"]
pod_sc = spec.get("securityContext", {})
containers = spec.get("containers", [])
if not containers:
    print("Deployment must define at least one container", file=sys.stderr)
    sys.exit(1)

if pod_sc.get("runAsNonRoot") is not True:
    print("Pod securityContext.runAsNonRoot must be true", file=sys.stderr)
    sys.exit(1)

seccomp = pod_sc.get("seccompProfile", {}).get("type")
if seccomp not in {"RuntimeDefault", "Localhost"}:
    print("Pod securityContext.seccompProfile.type must be RuntimeDefault or Localhost", file=sys.stderr)
    sys.exit(1)

for container in containers:
    sc = container.get("securityContext", {})
    if sc.get("allowPrivilegeEscalation") is not False:
        print(f"Container {container['name']} must set allowPrivilegeEscalation to false", file=sys.stderr)
        sys.exit(1)
    if sc.get("runAsUser", 1) == 0:
        print(f"Container {container['name']} must not run as UID 0", file=sys.stderr)
        sys.exit(1)
    caps = sc.get("capabilities", {})
    drop = caps.get("drop") or []
    if "ALL" not in drop:
        print(f"Container {container['name']} must drop ALL capabilities", file=sys.stderr)
        sys.exit(1)
    adds = caps.get("add") or []
    if adds and any(cap != "NET_BIND_SERVICE" for cap in adds):
        print(f"Container {container['name']} adds disallowed capabilities", file=sys.stderr)
        sys.exit(1)
PY

pod_name="$(kubectl get pods -n secure-lab -l app=policy-app -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)"
[ -n "${pod_name}" ] || fail "No running Pod found for policy-app"
kubectl wait --for=condition=Ready "pod/${pod_name}" -n secure-lab --timeout=120s >/dev/null 2>&1 || fail "Pod ${pod_name} is not Ready"

echo "Verification passed"
