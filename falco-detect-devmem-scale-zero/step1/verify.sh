#!/bin/bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get namespace falco >/dev/null 2>&1 || fail "Namespace falco not found"
kubectl get namespace runtime-lab >/dev/null 2>&1 || fail "Namespace runtime-lab not found"

kubectl get pod falco -n falco >/dev/null 2>&1 || fail "Falco Pod not found"
kubectl wait --for=condition=Ready pod/falco -n falco --timeout=120s >/dev/null 2>&1 || fail "Falco Pod is not ready"

falco_logs="$(kubectl logs -n falco pod/falco -c falco 2>/dev/null || true)"
echo "${falco_logs}" | grep -q 'file=/dev/mem' || fail "Falco logs do not contain the staged /dev/mem alert"
echo "${falco_logs}" | grep -q 'deployment=mem-reader' || fail "Falco logs do not identify the flagged deployment"

kubectl get deployment mem-reader -n runtime-lab >/dev/null 2>&1 || fail "Deployment mem-reader not found"

replicas="$(kubectl get deployment mem-reader -n runtime-lab -o jsonpath='{.spec.replicas}')"
[ "${replicas}" = "0" ] || fail "Deployment mem-reader must be scaled to 0 replicas"

ready_replicas="$(kubectl get deployment mem-reader -n runtime-lab -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)"
[ -z "${ready_replicas}" ] || [ "${ready_replicas}" = "0" ] || fail "Deployment mem-reader still has ready replicas"

pod_count="$(kubectl get pods -n runtime-lab -l app=mem-reader --no-headers 2>/dev/null | wc -l | tr -d ' ')"
[ "${pod_count}" = "0" ] || fail "Flagged Pods for mem-reader are still running"

safe_replicas="$(kubectl get deployment api-safe -n runtime-lab -o jsonpath='{.spec.replicas}')"
[ "${safe_replicas}" = "1" ] || fail "Safe deployment api-safe should remain at 1 replica"

echo "Verification passed"
