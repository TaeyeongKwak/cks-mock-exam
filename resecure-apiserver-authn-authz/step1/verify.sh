#!/bin/bash
set -euo pipefail

MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"
KUBECONFIG="/etc/kubernetes/admin.conf"

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

grep -q -- '--authorization-mode=Node,RBAC' "${MANIFEST}" || fail "kube-apiserver must use --authorization-mode=Node,RBAC"
grep -q -- '--anonymous-auth=false' "${MANIFEST}" || fail "kube-apiserver must disable anonymous authentication"

admission_line="$(grep -- '--enable-admission-plugins=' "${MANIFEST}" || true)"
echo "${admission_line}" | grep -q 'NodeRestriction' || fail "NodeRestriction must be enabled in --enable-admission-plugins"

kubectl --kubeconfig="${KUBECONFIG}" get clusterrolebinding anonymous-admin-binding >/dev/null 2>&1 && fail "ClusterRoleBinding anonymous-admin-binding still exists"

anonymous_code="$(curl -ks -o /dev/null -w "%{http_code}" https://127.0.0.1:6443/api || true)"
if [ "${anonymous_code}" = "200" ]; then
  fail "Anonymous requests are still allowed"
fi

kubectl --kubeconfig="${KUBECONFIG}" get nodes >/dev/null 2>&1 || fail "Authenticated kubectl access with /etc/kubernetes/admin.conf failed"

echo "Verification passed"
