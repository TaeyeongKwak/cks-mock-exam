#!/bin/bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get serviceaccount default -n default >/dev/null 2>&1 || fail "default ServiceAccount not found"

sa_automount="$(kubectl get serviceaccount default -n default -o jsonpath='{.automountServiceAccountToken}')"
[ "${sa_automount}" = "false" ] || fail "default ServiceAccount must have automountServiceAccountToken=false"

kubectl get pod jwt-demo -n default >/dev/null 2>&1 || fail "Pod jwt-demo not found"
kubectl wait --for=condition=Ready pod/jwt-demo -n default --timeout=120s >/dev/null 2>&1 || fail "Pod jwt-demo is not Ready"

pod_sa="$(kubectl get pod jwt-demo -n default -o jsonpath='{.spec.serviceAccountName}')"
[ "${pod_sa}" = "default" ] || fail "Pod jwt-demo must use the default ServiceAccount"

pod_automount="$(kubectl get pod jwt-demo -n default -o jsonpath='{.spec.automountServiceAccountToken}' 2>/dev/null || true)"
if [ "${pod_automount}" = "true" ]; then
  fail "Pod jwt-demo must not override automountServiceAccountToken back to true"
fi

projection_info="$(kubectl get pod jwt-demo -n default -o go-template='{{range .spec.volumes}}{{if .projected}}{{ $volumeName := .name }}{{range .projected.sources}}{{if .serviceAccountToken}}{{printf "%s|%s\n" $volumeName .serviceAccountToken.path}}{{end}}{{end}}{{end}}{{end}}' | tr -d "\r")"
[ -n "${projection_info}" ] || fail "Pod jwt-demo must define a projected ServiceAccount token volume"

projected_volume="$(echo "${projection_info}" | awk -F'|' '$2=="token.jwt" {print $1; exit}')"
[ -n "${projected_volume}" ] || fail "Projected ServiceAccount token volume must expose path token.jwt"

mounts="$(kubectl get pod jwt-demo -n default -o go-template='{{range .spec.containers}}{{range .volumeMounts}}{{printf "%s|%s|%s\n" .name .mountPath .subPath}}{{end}}{{end}}' | tr -d "\r")"
[ -n "${mounts}" ] || fail "Pod jwt-demo has no volume mounts"

mount_ok="$(echo "${mounts}" | awk -F'|' -v volume="${projected_volume}" '
$1==volume && $2=="/var/run/secrets/tokens/token.jwt" && $3=="token.jwt" {print "yes"; exit}
$1==volume && ($2=="/var/run/secrets/tokens" || $2=="/var/run/secrets/tokens/") {print "yes"; exit}
')"
[ "${mount_ok:-}" = "yes" ] || fail "Projected token volume must be mounted so the token is available at /var/run/secrets/tokens/token.jwt"

token_size="$(kubectl exec -n default jwt-demo -- sh -c 'test -f /var/run/secrets/tokens/token.jwt && wc -c </var/run/secrets/tokens/token.jwt' 2>/dev/null | tr -d " ")"
[ -n "${token_size}" ] || fail "Projected token file is not present at /var/run/secrets/tokens/token.jwt inside the Pod"

if kubectl exec -n default jwt-demo -- sh -c 'test -f /var/run/secrets/kubernetes.io/serviceaccount/token'; then
  fail "Default ServiceAccount token path must not be mounted automatically"
fi

echo "Verification passed"
