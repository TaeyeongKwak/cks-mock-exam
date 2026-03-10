#!/bin/bash
set -euo pipefail

MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"
KUBECONFIG="/etc/kubernetes/admin.conf"

wait_api() {
  for _ in $(seq 1 90); do
    if kubectl --kubeconfig="${KUBECONFIG}" get --raw /readyz >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  return 1
}

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

cp "${MANIFEST}" /root/kube-apiserver.yaml.original

sed -i 's@--authorization-mode=.*@    - --authorization-mode=RBAC@' "${MANIFEST}"

if grep -q -- '--anonymous-auth=' "${MANIFEST}"; then
  sed -i 's@--anonymous-auth=.*@    - --anonymous-auth=true@' "${MANIFEST}"
else
  sed -i '/--authorization-mode=RBAC/a\    - --anonymous-auth=true' "${MANIFEST}"
fi

sed -i '/--enable-admission-plugins=/{
  s/NodeRestriction,//g
  s/,NodeRestriction//g
  s/NodeRestriction//g
}' "${MANIFEST}"

wait_api

kubectl --kubeconfig="${KUBECONFIG}" delete clusterrolebinding anonymous-admin-binding --ignore-not-found >/dev/null 2>&1 || true
kubectl --kubeconfig="${KUBECONFIG}" create clusterrolebinding anonymous-admin-binding --clusterrole=cluster-admin --user=system:anonymous >/dev/null

wait_api

for _ in $(seq 1 30); do
  code="$(curl -ks -o /dev/null -w "%{http_code}" https://127.0.0.1:6443/api || true)"
  if [ "${code}" = "200" ]; then
    exit 0
  fi
  sleep 2
done

echo "Failed to stage anonymous API access" >&2
exit 1
