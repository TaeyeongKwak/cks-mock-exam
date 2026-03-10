#!/bin/bash
set -euo pipefail

MANIFEST="/home/candidate/11/ui-pod.yaml"

fail() {
  echo "$1" >&2
  exit 1
}

[ -f "${MANIFEST}" ] || fail "Pod manifest not found at ${MANIFEST}"
kubectl get namespace qa-lab >/dev/null 2>&1 || fail "Namespace qa-lab not found"

kubectl get serviceaccount ui-sa -n qa-lab >/dev/null 2>&1 || fail "ServiceAccount ui-sa not found in qa-lab"
automount="$(kubectl get serviceaccount ui-sa -n qa-lab -o jsonpath='{.automountServiceAccountToken}')"
[ "${automount}" = "false" ] || fail "ServiceAccount ui-sa must have automountServiceAccountToken=false"

kubectl apply --dry-run=client -f "${MANIFEST}" >/dev/null 2>&1 || fail "Pod manifest is not valid YAML for kubectl"

manifest_sa="$(kubectl create --dry-run=client -f "${MANIFEST}" -o jsonpath='{.spec.serviceAccountName}' 2>/dev/null)"
[ "${manifest_sa}" = "ui-sa" ] || fail "Pod manifest must use serviceAccountName ui-sa"

manifest_name="$(kubectl create --dry-run=client -f "${MANIFEST}" -o jsonpath='{.metadata.name}' 2>/dev/null)"
[ "${manifest_name}" = "frontend-ui" ] || fail "Pod manifest must keep Pod name frontend-ui"

kubectl get pod frontend-ui -n qa-lab >/dev/null 2>&1 || fail "Pod frontend-ui not found in qa-lab"
kubectl wait --for=condition=Ready pod/frontend-ui -n qa-lab --timeout=120s >/dev/null 2>&1 || fail "Pod frontend-ui is not Ready"

pod_sa="$(kubectl get pod frontend-ui -n qa-lab -o jsonpath='{.spec.serviceAccountName}')"
[ "${pod_sa}" = "ui-sa" ] || fail "Running Pod frontend-ui must use ServiceAccount ui-sa"

for sa in frontend qa-helper legacy-builder; do
  if kubectl get serviceaccount "${sa}" -n qa-lab >/dev/null 2>&1; then
    fail "Unused ServiceAccount ${sa} still exists in namespace qa-lab"
  fi
done

sa_list="$(kubectl get serviceaccounts -n qa-lab -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | sort | tr -d '\r')"
expected_list="$(printf 'default\nui-sa')"
[ "${sa_list}" = "${expected_list}" ] || fail "Only default and ui-sa should remain in namespace qa-lab"

echo "Verification passed"
