#!/bin/bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

for ns in tenant-a tenant-b; do
  kubectl get namespace "${ns}" >/dev/null 2>&1 || fail "Namespace ${ns} not found"
done

for pod in local-probe catalog-http catalog-admin; do
  kubectl wait -n tenant-a --for=condition=Ready "pod/${pod}" --timeout=120s >/dev/null 2>&1 || fail "Pod ${pod} is not Ready in tenant-a"
done
kubectl wait -n tenant-b --for=condition=Ready pod/remote-probe --timeout=120s >/dev/null 2>&1 || fail "Pod remote-probe is not Ready in tenant-b"

policy_json="$(kubectl get networkpolicy tenant-http-only -n tenant-a -o json 2>/dev/null)" || fail "NetworkPolicy tenant-http-only not found in tenant-a"

POLICY_JSON="${policy_json}" python3 - <<'PY' || exit 1
import json
import os
import sys

data = json.loads(os.environ["POLICY_JSON"])
spec = data.get("spec", {})

types = set(spec.get("policyTypes") or [])
if types != {"Ingress"}:
    print("NetworkPolicy must declare only Ingress in policyTypes", file=sys.stderr)
    sys.exit(1)

selector = spec.get("podSelector") or {}
if selector.get("matchLabels") not in ({}, None) or selector.get("matchExpressions") not in (None, []):
    print("NetworkPolicy must apply to every Pod in tenant-a", file=sys.stderr)
    sys.exit(1)

ingress = spec.get("ingress") or []
if len(ingress) != 1:
    print("NetworkPolicy must define exactly one ingress rule", file=sys.stderr)
    sys.exit(1)

rule = ingress[0]
ports = rule.get("ports") or []
if len(ports) != 1:
    print("Ingress rule must expose only one port", file=sys.stderr)
    sys.exit(1)

port = ports[0]
if str(port.get("port")) != "80" or str(port.get("protocol", "TCP")).upper() != "TCP":
    print("Ingress rule must allow only TCP port 80", file=sys.stderr)
    sys.exit(1)

peers = rule.get("from") or []
if len(peers) != 1:
    print("Ingress rule must allow exactly one peer selector", file=sys.stderr)
    sys.exit(1)

peer = peers[0]
if peer.get("podSelector") != {} or "namespaceSelector" in peer:
    print("Ingress rule must allow only same-namespace Pods", file=sys.stderr)
    sys.exit(1)
PY

http_ip="$(kubectl get pod catalog-http -n tenant-a -o jsonpath='{.status.podIP}')"
admin_ip="$(kubectl get pod catalog-admin -n tenant-a -o jsonpath='{.status.podIP}')"
[ -n "${http_ip}" ] || fail "Could not determine Pod IP for catalog-http"
[ -n "${admin_ip}" ] || fail "Could not determine Pod IP for catalog-admin"

allowed="$(kubectl exec -n tenant-a local-probe -- sh -c "wget -qO- --timeout=3 http://${http_ip}:80" 2>/dev/null || true)"
[ "${allowed}" = "tenant-a-http" ] || fail "Internal HTTP traffic to catalog-http on port 80 should be allowed"

if kubectl exec -n tenant-a local-probe -- sh -c "wget -qO- --timeout=3 http://${admin_ip}:8080" >/dev/null 2>&1; then
  fail "Traffic to the alternate service port should be blocked"
fi

if kubectl exec -n tenant-b remote-probe -- sh -c "wget -qO- --timeout=3 http://${http_ip}:80" >/dev/null 2>&1; then
  fail "Cross-namespace traffic to tenant-a HTTP service should be blocked"
fi

echo "Verification passed"
