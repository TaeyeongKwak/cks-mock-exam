#!/bin/bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get ns mesh-zone >/dev/null 2>&1 || fail "Namespace mesh-zone not found"
kubectl get cnp mesh-open -n mesh-zone >/dev/null 2>&1 || fail "Existing CiliumNetworkPolicy mesh-open not found in mesh-zone"
kubectl get deploy order-api order-db echo-store diagnostics -n mesh-zone >/dev/null 2>&1 || fail "Expected deployments are missing in mesh-zone"
kubectl get svc echo-store -n mesh-zone >/dev/null 2>&1 || fail "Service echo-store not found"

python3 - <<'PY'
import json
import subprocess
import sys

def fail(msg: str) -> None:
    print(msg, file=sys.stderr)
    sys.exit(1)

def get_json(args):
    return json.loads(subprocess.check_output(args, text=True))

def has_labels(selector, expected):
    labels = selector.get("matchLabels", {}) if isinstance(selector, dict) else {}
    return all(labels.get(k) == v for k, v in expected.items())

policy1 = get_json(["kubectl", "get", "cnp", "db-authz", "-n", "mesh-zone", "-o", "json"])
spec1 = policy1.get("spec", {})
if not has_labels(spec1.get("endpointSelector", {}), {"tier": "db"}):
    fail("db-authz must select Pods with tier=db")

auth_ok = False
for rule in spec1.get("egress", []) or []:
    if rule.get("authentication", {}).get("mode") != "required":
        continue
    for endpoint in rule.get("toEndpoints", []) or []:
        if has_labels(endpoint, {"tier": "api"}):
            auth_ok = True
            break
    if auth_ok:
        break
if not auth_ok:
    fail("db-authz must require authentication for egress to tier=api")

policy2 = get_json(["kubectl", "get", "cnp", "no-icmp-probe", "-n", "mesh-zone", "-o", "json"])
spec2 = policy2.get("spec", {})
if not has_labels(spec2.get("endpointSelector", {}), {"app": "diagnostics"}):
    fail("no-icmp-probe must select Pods with app=diagnostics")

deny_ok = False
icmp_ok = False
for rule in spec2.get("egressDeny", []) or []:
    if rule.get("icmps"):
        icmp_ok = True
    for endpoint in rule.get("toEndpoints", []) or []:
        if has_labels(endpoint, {"service": "echo-store"}) or has_labels(endpoint, {"app": "echo-store"}):
            deny_ok = True
    for svc in rule.get("toServices", []) or []:
        ref = svc.get("k8sService", {})
        if ref.get("serviceName") == "echo-store" and ref.get("namespace") == "mesh-zone":
            deny_ok = True
if not deny_ok:
    fail("no-icmp-probe must target the echo-store workload")
if not icmp_ok:
    fail("no-icmp-probe must scope the deny rule to ICMP traffic")

print("Verification passed")
PY
