#!/bin/bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get namespace qa-lab >/dev/null 2>&1 || fail "Namespace qa-lab not found"
kubectl get serviceaccount backend-team -n qa-lab >/dev/null 2>&1 || fail "ServiceAccount backend-team not found in qa-lab"
kubectl get pod frontend-ui -n qa-lab >/dev/null 2>&1 || fail "Pod frontend-ui not found in qa-lab"
kubectl wait --for=condition=Ready pod/frontend-ui -n qa-lab --timeout=120s >/dev/null 2>&1 || fail "Pod frontend-ui is not Ready"

service_account_name="$(kubectl get pod frontend-ui -n qa-lab -o jsonpath='{.spec.serviceAccountName}')"
[ "${service_account_name}" = "backend-team" ] || fail "Pod frontend-ui must use ServiceAccount backend-team"

for verb in get list watch create update patch delete; do
  can_i="$(kubectl auth can-i "${verb}" secrets -n qa-lab --as=system:serviceaccount:qa-lab:backend-team 2>/dev/null || true)"
  if [ "${can_i}" = "yes" ]; then
    fail "ServiceAccount backend-team must not be allowed to ${verb} secrets in namespace qa-lab"
  fi
done

secret_lookup="$(kubectl auth can-i get secret/qa-api-key -n qa-lab --as=system:serviceaccount:qa-lab:backend-team 2>/dev/null || true)"
if [ "${secret_lookup}" = "yes" ]; then
  fail "ServiceAccount backend-team must not be allowed to read Secret qa-api-key"
fi

echo "Verification passed"
