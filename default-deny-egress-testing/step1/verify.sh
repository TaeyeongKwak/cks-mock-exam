#!/bin/bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get namespace sandbox >/dev/null 2>&1 || fail "Namespace sandbox not found"
kubectl get networkpolicy outbound-lock -n sandbox >/dev/null 2>&1 || fail "NetworkPolicy outbound-lock not found in sandbox"

policy_json="$(kubectl get networkpolicy outbound-lock -n sandbox -o json)"
POLICY_JSON="${policy_json}" python3 - <<'PY' || exit 1
import json
import os
import sys

data = json.loads(os.environ["POLICY_JSON"])
spec = data.get("spec", {})

types = set(spec.get("policyTypes") or [])
if types != {"Egress"}:
    print("NetworkPolicy must declare only Egress in policyTypes", file=sys.stderr)
    sys.exit(1)

selector = spec.get("podSelector") or {}
if selector.get("matchLabels") or selector.get("matchExpressions"):
    print("NetworkPolicy must select all Pods in sandbox", file=sys.stderr)
    sys.exit(1)

egress = spec.get("egress")
if egress is None:
    print("spec.egress must be present", file=sys.stderr)
    sys.exit(1)

if len(egress) == 0:
    sys.exit(0)

for rule in egress:
    ports = rule.get("ports") or []
    if not ports:
      print("Any allowed egress rule must pin traffic to DNS ports", file=sys.stderr)
      sys.exit(1)
    for port in ports:
        if port.get("port") != 53:
            print("Allowed egress must be limited to port 53", file=sys.stderr)
            sys.exit(1)
        if str(port.get("protocol", "TCP")).upper() not in {"TCP", "UDP"}:
            print("Allowed egress on port 53 must use TCP or UDP", file=sys.stderr)
            sys.exit(1)
PY

policy_count="$(kubectl get networkpolicy -n sandbox --no-headers 2>/dev/null | wc -l | tr -d ' ')"
[ "${policy_count}" = "1" ] || fail "Only one NetworkPolicy should exist in namespace sandbox"

echo "Verification passed"
