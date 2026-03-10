#!/bin/bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get namespace shipping >/dev/null 2>&1 || fail "Namespace shipping not found"

for keep_pod in ledger-api metrics-sidecar; do
  kubectl get pod "${keep_pod}" -n shipping >/dev/null 2>&1 || fail "Approved Pod ${keep_pod} must remain"
  kubectl wait --for=condition=Ready "pod/${keep_pod}" -n shipping --timeout=120s >/dev/null 2>&1 || fail "Approved Pod ${keep_pod} is not Ready"
done

remaining_rejected="$(kubectl get pods -n shipping -l lab.cleanup=remove --no-headers 2>/dev/null | wc -l | tr -d '[:space:]')"
[ "${remaining_rejected}" = "0" ] || fail "Rejected Pods are still present in shipping"

keep_count="$(kubectl get pods -n shipping -l lab.cleanup=keep --no-headers 2>/dev/null | wc -l | tr -d '[:space:]')"
[ "${keep_count}" = "2" ] || fail "The approved Pod set in shipping changed unexpectedly"

for keep_pod in ledger-api metrics-sidecar; do
  privileged="$(kubectl get pod "${keep_pod}" -n shipping -o jsonpath='{.spec.containers[0].securityContext.privileged}')"
  readonly="$(kubectl get pod "${keep_pod}" -n shipping -o jsonpath='{.spec.containers[0].securityContext.readOnlyRootFilesystem}')"
  [ "${privileged}" = "false" ] || fail "${keep_pod} must remain unprivileged"
  [ "${readonly}" = "true" ] || fail "${keep_pod} must keep a read-only root filesystem"
done

total_pods="$(kubectl get pods -n shipping --no-headers 2>/dev/null | wc -l | tr -d '[:space:]')"
[ "${total_pods}" = "2" ] || fail "Only the approved Pods should remain in shipping"

echo "Verification passed"
