#!/bin/bash
set -euo pipefail

KUBECONFIG="/etc/kubernetes/admin.conf"
RUNTIMECLASS_FILE="/root/10/isolated-class.yaml"

fail() {
  echo "$1" >&2
  exit 1
}

wait_api() {
  for _ in $(seq 1 90); do
    if kubectl --kubeconfig="${KUBECONFIG}" get --raw /readyz >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  return 1
}

wait_api || fail "API server is not ready"

[ -f "${RUNTIMECLASS_FILE}" ] || fail "RuntimeClass manifest not found at ${RUNTIMECLASS_FILE}"

kubectl create --dry-run=client -f "${RUNTIMECLASS_FILE}" >/dev/null 2>&1 || fail "RuntimeClass manifest is not valid"

file_name="$(kubectl create --dry-run=client -f "${RUNTIMECLASS_FILE}" -o jsonpath='{.metadata.name}' 2>/dev/null)"
[ "${file_name}" = "isolated" ] || fail "RuntimeClass file must define metadata.name=isolated"

file_handler="$(kubectl create --dry-run=client -f "${RUNTIMECLASS_FILE}" -o jsonpath='{.handler}' 2>/dev/null)"
[ "${file_handler}" = "runsc" ] || fail "RuntimeClass file must define handler=runsc"

kubectl get runtimeclass isolated >/dev/null 2>&1 || fail "RuntimeClass isolated not found"

live_handler="$(kubectl get runtimeclass isolated -o jsonpath='{.handler}')"
[ "${live_handler}" = "runsc" ] || fail "RuntimeClass isolated must use handler runsc"

for pod in svc-a svc-b; do
  kubectl get pod "${pod}" -n backend >/dev/null 2>&1 || fail "Pod ${pod} not found in namespace backend"
  kubectl wait --for=condition=Ready "pod/${pod}" -n backend --timeout=120s >/dev/null 2>&1 || fail "Pod ${pod} is not Ready"

  runtime_class="$(kubectl get pod "${pod}" -n backend -o jsonpath='{.spec.runtimeClassName}')"
  [ "${runtime_class}" = "isolated" ] || fail "Pod ${pod} must use runtimeClassName=isolated"

  node_name="$(kubectl get pod "${pod}" -n backend -o jsonpath='{.spec.nodeName}')"
  [ "${node_name}" = "controlplane" ] || fail "Pod ${pod} must remain on controlplane in this scenario"
done

all_runtime_classes="$(kubectl get pods -n backend -o go-template='{{range .items}}{{printf "%s:%s\n" .metadata.name .spec.runtimeClassName}}{{end}}' | tr -d '\r')"
for expected in "svc-a:isolated" "svc-b:isolated"; do
  echo "${all_runtime_classes}" | grep -qx "${expected}" || fail "Expected ${expected} in namespace backend"
done

remaining_count="$(kubectl get pods -n backend --no-headers 2>/dev/null | wc -l | tr -d ' ')"
[ "${remaining_count}" = "2" ] || fail "Exactly two Pods should exist in namespace backend"

echo "Verification passed"
