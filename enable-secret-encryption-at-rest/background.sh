#!/bin/bash
set -euo pipefail

MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"
ENC_CONFIG="/etc/kubernetes/pki/encryption-config.yaml"
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

cp "${MANIFEST}" /root/kube-apiserver.yaml.encryption.bak

sed -i '/--encryption-provider-config=/d' "${MANIFEST}"
rm -f "${ENC_CONFIG}"

if ! wait_api; then
  echo "API server did not become ready after removing encryption-provider-config" >&2
  exit 1
fi

kubectl --kubeconfig="${KUBECONFIG}" delete secret app-secret -n default --ignore-not-found >/dev/null 2>&1 || true
kubectl --kubeconfig="${KUBECONFIG}" create secret generic app-secret -n default --from-literal=password=verysecretvalue >/dev/null
