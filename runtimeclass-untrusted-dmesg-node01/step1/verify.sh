#!/bin/bash
set -euo pipefail

KUBECONFIG="/etc/kubernetes/admin.conf"
RUNTIMECLASS_FILE="/opt/course/7/runtime-alt.yaml"
DMESG_FILE="/opt/course/7/guestbox-dmesg.log"

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
[ "${file_name}" = "sandbox-alt" ] || fail "RuntimeClass file must define metadata.name=sandbox-alt"

file_handler="$(kubectl create --dry-run=client -f "${RUNTIMECLASS_FILE}" -o jsonpath='{.handler}' 2>/dev/null)"
[ "${file_handler}" = "runsc" ] || fail "RuntimeClass file must define handler=runsc"

kubectl get runtimeclass sandbox-alt >/dev/null 2>&1 || fail "RuntimeClass sandbox-alt not found"
live_handler="$(kubectl get runtimeclass sandbox-alt -o jsonpath='{.handler}')"
[ "${live_handler}" = "runsc" ] || fail "RuntimeClass sandbox-alt must use handler runsc"

kubectl get pod guestbox -n default >/dev/null 2>&1 || fail "Pod guestbox not found in default namespace"
kubectl wait --for=condition=Ready pod/guestbox -n default --timeout=180s >/dev/null 2>&1 || fail "Pod guestbox is not Ready"

pod_image="$(kubectl get pod guestbox -n default -o jsonpath='{.spec.containers[0].image}')"
[ "${pod_image}" = "alpine:3.18" ] || fail "Pod guestbox must use image alpine:3.18"

runtime_class="$(kubectl get pod guestbox -n default -o jsonpath='{.spec.runtimeClassName}')"
[ "${runtime_class}" = "sandbox-alt" ] || fail "Pod guestbox must use runtimeClassName=sandbox-alt"

node_name="$(kubectl get pod guestbox -n default -o jsonpath='{.spec.nodeName}')"
[ "${node_name}" = "node01" ] || fail "Pod guestbox must run on node01"

[ -f "${DMESG_FILE}" ] || fail "dmesg output file not found at ${DMESG_FILE}"
[ -s "${DMESG_FILE}" ] || fail "dmesg output file is empty"

fresh_output="$(kubectl exec -n default guestbox -- dmesg 2>&1 || true)"
[ -n "${fresh_output}" ] || fail "Pod did not produce any dmesg output"

file_preview="$(head -n 1 "${DMESG_FILE}" 2>/dev/null || true)"
[ -n "${file_preview}" ] || fail "dmesg output file has no readable content"

grep -Fq "${file_preview}" <<<"${fresh_output}" || fail "Saved dmesg output does not appear to come from the running Pod"

echo "Verification passed"
