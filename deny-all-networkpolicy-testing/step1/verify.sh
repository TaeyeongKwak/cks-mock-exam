#!/bin/bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get namespace quarantine >/dev/null 2>&1 || fail "Namespace quarantine not found"
kubectl get namespace edge >/dev/null 2>&1 || fail "Namespace edge not found"
kubectl get networkpolicy air-gap -n quarantine >/dev/null 2>&1 || fail "NetworkPolicy air-gap not found in quarantine"

policy_types="$(kubectl get networkpolicy air-gap -n quarantine -o go-template='{{range .spec.policyTypes}}{{printf "%s\n" .}}{{end}}')"
echo "${policy_types}" | grep -qx 'Ingress' || fail "policyTypes must include Ingress"
echo "${policy_types}" | grep -qx 'Egress' || fail "policyTypes must include Egress"

selector_size="$(kubectl get networkpolicy air-gap -n quarantine -o go-template='{{if .spec.podSelector.matchLabels}}{{len .spec.podSelector.matchLabels}}{{else}}0{{end}}')"
selector_expr_size="$(kubectl get networkpolicy air-gap -n quarantine -o go-template='{{if .spec.podSelector.matchExpressions}}{{len .spec.podSelector.matchExpressions}}{{else}}0{{end}}')"
[ "${selector_size}" = "0" ] || fail "air-gap must target all Pods"
[ "${selector_expr_size}" = "0" ] || fail "air-gap must target all Pods"

ingress_rules="$(kubectl get networkpolicy air-gap -n quarantine -o go-template='{{if .spec.ingress}}{{len .spec.ingress}}{{else}}0{{end}}')"
egress_rules="$(kubectl get networkpolicy air-gap -n quarantine -o go-template='{{if .spec.egress}}{{len .spec.egress}}{{else}}0{{end}}')"
[ "${ingress_rules}" = "0" ] || fail "Ingress rules must stay empty"
[ "${egress_rules}" = "0" ] || fail "Egress rules must stay empty"

vault_ip="$(kubectl get pod vault-api -n quarantine -o jsonpath='{.status.podIP}')"
edge_ip="$(kubectl get pod edge-api -n edge -o jsonpath='{.status.podIP}')"
[ -n "${vault_ip}" ] || fail "vault-api Pod IP not found"
[ -n "${edge_ip}" ] || fail "edge-api Pod IP not found"

if kubectl exec -n quarantine inside-check -- sh -c "wget -T 2 -qO- http://${vault_ip}:8080/hostname >/dev/null" >/dev/null 2>&1; then
  fail "inside-check can still reach vault-api"
fi

if kubectl exec -n quarantine inside-check -- sh -c "wget -T 2 -qO- http://${edge_ip}:8080/hostname >/dev/null" >/dev/null 2>&1; then
  fail "inside-check can still reach edge-api"
fi

if kubectl exec -n edge edge-check -- sh -c "wget -T 2 -qO- http://${vault_ip}:8080/hostname >/dev/null" >/dev/null 2>&1; then
  fail "edge-check can still reach vault-api"
fi

echo "Verification passed"
