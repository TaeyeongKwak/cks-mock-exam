#!/bin/bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get serviceaccount default -n default >/dev/null 2>&1 || fail "default ServiceAccount not found"

sa_automount="$(kubectl get serviceaccount default -n default -o jsonpath='{.automountServiceAccountToken}')"
[ "${sa_automount}" = "false" ] || fail "default ServiceAccount must have automountServiceAccountToken=false"

kubectl get pod web-token-pod -n default >/dev/null 2>&1 || fail "Pod web-token-pod not found"
kubectl wait --for=condition=Ready pod/web-token-pod -n default --timeout=120s >/dev/null 2>&1 || fail "Pod web-token-pod is not Ready"

pod_sa="$(kubectl get pod web-token-pod -n default -o jsonpath='{.spec.serviceAccountName}')"
[ "${pod_sa}" = "default" ] || fail "Pod web-token-pod must use the default ServiceAccount"

mounts="$(kubectl get pod web-token-pod -n default -o go-template='{{range .spec.containers}}{{range .volumeMounts}}{{printf "%s|%s|%s\n" .name .mountPath .subPath}}{{end}}{{end}}' | tr -d '\r')"

mount_match="$(echo "${mounts}" | awk -F'|' '$2=="/var/run/secrets/kubernetes.io/serviceaccount/token" && ($3=="" || $3=="token") {print; exit}')"

if [ -z "${mount_match}" ]; then
  mount_match="$(echo "${mounts}" | awk -F'|' '$2=="/var/run/secrets/kubernetes.io/serviceaccount" || $2=="/var/run/secrets/kubernetes.io/serviceaccount/" {print; exit}')"
fi

[ -n "${mount_match}" ] || fail "Pod must expose the ServiceAccount token at /var/run/secrets/kubernetes.io/serviceaccount/token"

volume_name="$(echo "${mount_match}" | head -n 1 | cut -d'|' -f1)"
[ -n "${volume_name}" ] || fail "Unable to determine the mounted volume name"

secret_name="$(kubectl get pod web-token-pod -n default -o go-template="{{range .spec.volumes}}{{if eq .name \"${volume_name}\"}}{{if .secret}}{{.secret.secretName}}{{end}}{{end}}{{end}}" | tr -d '\r')"
[ -n "${secret_name}" ] || fail "Mounted token path must come from a Secret volume"

secret_type="$(kubectl get secret "${secret_name}" -n default -o jsonpath='{.type}' 2>/dev/null || true)"
[ "${secret_type}" = "kubernetes.io/service-account-token" ] || fail "Mounted Secret must be of type kubernetes.io/service-account-token"

secret_sa="$(kubectl get secret "${secret_name}" -n default -o jsonpath='{.metadata.annotations.kubernetes\.io/service-account\.name}' 2>/dev/null || true)"
[ "${secret_sa}" = "default" ] || fail "Mounted Secret must reference the default ServiceAccount"

for _ in $(seq 1 30); do
  token_data="$(kubectl get secret "${secret_name}" -n default -o jsonpath='{.data.token}' 2>/dev/null || true)"
  if [ -n "${token_data}" ]; then
    break
  fi
  sleep 2
done
[ -n "${token_data:-}" ] || fail "ServiceAccount token Secret was not populated with token data"

automount_override="$(kubectl get pod web-token-pod -n default -o jsonpath='{.spec.automountServiceAccountToken}' 2>/dev/null || true)"
if [ "${automount_override}" = "true" ]; then
  fail "Pod must not override ServiceAccount token automount back to true"
fi

token_file_present="$(kubectl exec -n default web-token-pod -- sh -c 'test -f /var/run/secrets/kubernetes.io/serviceaccount/token && wc -c </var/run/secrets/kubernetes.io/serviceaccount/token' 2>/dev/null || true)"
[ -n "${token_file_present}" ] || fail "Token file is not present inside the Pod"

echo "Verification passed"
