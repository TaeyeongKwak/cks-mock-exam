#!/bin/bash
set -euo pipefail

MANIFEST="/root/policy-lab/blanket-policy.yaml"

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get namespace vault >/dev/null 2>&1 || fail "Namespace vault not found"
[ -f "${MANIFEST}" ] || fail "Manifest not found at ${MANIFEST}"
kubectl get networkpolicy blanket-policy -n vault >/dev/null 2>&1 || fail "NetworkPolicy blanket-policy not found in vault"

types="$(kubectl get networkpolicy blanket-policy -n vault -o go-template='{{range .spec.policyTypes}}{{printf "%s\n" .}}{{end}}')"
echo "${types}" | grep -qx 'Ingress' || fail "policyTypes must include Ingress"
echo "${types}" | grep -qx 'Egress' || fail "policyTypes must include Egress"

ingress_count="$(kubectl get networkpolicy blanket-policy -n vault -o go-template='{{if .spec.ingress}}{{len .spec.ingress}}{{else}}0{{end}}')"
egress_count="$(kubectl get networkpolicy blanket-policy -n vault -o go-template='{{if .spec.egress}}{{len .spec.egress}}{{else}}0{{end}}')"
[ "${ingress_count}" = "0" ] || fail "Ingress rules must be empty to deny all ingress traffic"
[ "${egress_count}" = "0" ] || fail "Egress rules must be empty to deny all egress traffic"

match_labels_count="$(kubectl get networkpolicy blanket-policy -n vault -o go-template='{{if .spec.podSelector.matchLabels}}{{len .spec.podSelector.matchLabels}}{{else}}0{{end}}')"
match_expressions_count="$(kubectl get networkpolicy blanket-policy -n vault -o go-template='{{if .spec.podSelector.matchExpressions}}{{len .spec.podSelector.matchExpressions}}{{else}}0{{end}}')"
[ "${match_labels_count}" = "0" ] || fail "podSelector must select all Pods"
[ "${match_expressions_count}" = "0" ] || fail "podSelector must select all Pods"

echo "Verification passed"
