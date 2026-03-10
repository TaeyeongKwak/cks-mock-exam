#!/bin/bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get networkpolicy ingress-guard -n app-team >/dev/null 2>&1 || fail "NetworkPolicy ingress-guard not found in app-team"
kubectl get pod catalog-service -n app-team >/dev/null 2>&1 || fail "Pod catalog-service not found"

policy_json="$(kubectl get networkpolicy ingress-guard -n app-team -o json)"
POLICY_JSON="${policy_json}" python3 - <<'PY' || exit 1
import json
import os
import sys

data = json.loads(os.environ["POLICY_JSON"])
spec = data.get("spec", {})
selector = spec.get("podSelector", {}).get("matchLabels", {})
if selector.get("app") != "catalog-service":
    print("NetworkPolicy must target Pod catalog-service via label app=catalog-service", file=sys.stderr)
    sys.exit(1)

policy_types = set(spec.get("policyTypes", []))
if "Ingress" not in policy_types:
    print("NetworkPolicy must include policyTypes: Ingress", file=sys.stderr)
    sys.exit(1)

ingress = spec.get("ingress", [])
if not ingress:
    print("NetworkPolicy must define ingress rules", file=sys.stderr)
    sys.exit(1)

same_ns_ok = False
testing_any_ns_ok = False
for rule in ingress:
    for peer in rule.get("from", []):
        ns_sel = peer.get("namespaceSelector")
        pod_sel = peer.get("podSelector")
        if pod_sel is None and ns_sel is None:
            continue
        if pod_sel == {} and ns_sel is None:
            same_ns_ok = True
        labels = (pod_sel or {}).get("matchLabels", {})
        if labels.get("environment") == "testing" and ns_sel == {}:
            testing_any_ns_ok = True

if not same_ns_ok:
    print("NetworkPolicy must allow Pods from the same namespace", file=sys.stderr)
    sys.exit(1)
if not testing_any_ns_ok:
    print("NetworkPolicy must allow Pods labeled environment=testing from any namespace", file=sys.stderr)
    sys.exit(1)
PY

product_ip="$(kubectl get pod catalog-service -n app-team -o jsonpath='{.status.podIP}')"
[ -n "${product_ip}" ] || fail "Could not determine catalog-service Pod IP"

same_ns_out="$(kubectl exec -n app-team same-ns-client -- sh -c "wget -qO- --timeout=3 http://${product_ip}:5678" 2>/dev/null || true)"
[ "${same_ns_out}" = "products-ok" ] || fail "Traffic from same namespace should be allowed"

testing_out="$(kubectl exec -n qa-lab testing-client -- sh -c "wget -qO- --timeout=3 http://${product_ip}:5678" 2>/dev/null || true)"
[ "${testing_out}" = "products-ok" ] || fail "Traffic from environment=testing Pod should be allowed"

if kubectl exec -n misc-team denied-client -- sh -c "wget -qO- --timeout=3 http://${product_ip}:5678" >/dev/null 2>&1; then
  fail "Traffic from unlabeled Pod in another namespace should be blocked"
fi

echo "Verification passed"
