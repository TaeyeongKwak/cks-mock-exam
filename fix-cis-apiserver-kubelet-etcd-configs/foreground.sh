#!/bin/bash
set -euo pipefail

APISERVER="/etc/kubernetes/manifests/kube-apiserver.yaml"
ETCD="/etc/kubernetes/manifests/etcd.yaml"
KUBELET_CONFIG="/var/lib/kubelet/config.yaml"
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

cp "${APISERVER}" /root/kube-apiserver.yaml.cis-review.bak
cp "${ETCD}" /root/etcd.yaml.cis-review.bak
cp "${KUBELET_CONFIG}" /root/kubelet-config.yaml.cis-review.bak

if grep -q -- '--authorization-mode=' "${APISERVER}"; then
  sed -i 's@--authorization-mode=.*@    - --authorization-mode=AlwaysAllow@' "${APISERVER}"
else
  sed -i '/--anonymous-auth=/a\    - --authorization-mode=AlwaysAllow' "${APISERVER}"
fi

python3 - <<'PY'
from pathlib import Path
path = Path("/var/lib/kubelet/config.yaml")
text = path.read_text()

if "anonymous:\n    enabled: false" in text:
    text = text.replace("anonymous:\n    enabled: false", "anonymous:\n    enabled: true")
elif "anonymous:\n      enabled: false" in text:
    text = text.replace("anonymous:\n      enabled: false", "anonymous:\n      enabled: true")
elif "authentication:" not in text:
    text += "\nauthentication:\n  anonymous:\n    enabled: true\n"

if "authorization:\n  mode: Webhook" in text:
    text = text.replace("authorization:\n  mode: Webhook", "authorization:\n  mode: AlwaysAllow")
elif "authorization:\n    mode: Webhook" in text:
    text = text.replace("authorization:\n    mode: Webhook", "authorization:\n    mode: AlwaysAllow")
elif "authorization:" not in text:
    text += "\nauthorization:\n  mode: AlwaysAllow\n"

path.write_text(text)
PY

if grep -q -- '--client-cert-auth=' "${ETCD}"; then
  sed -i 's@--client-cert-auth=.*@    - --client-cert-auth=false@' "${ETCD}"
else
  sed -i '/--trusted-ca-file=/a\    - --client-cert-auth=false' "${ETCD}"
fi

if grep -q -- '--auto-tls=' "${ETCD}"; then
  sed -i 's@--auto-tls=.*@    - --auto-tls=true@' "${ETCD}"
else
  sed -i '/--cert-file=/a\    - --auto-tls=true' "${ETCD}"
fi

systemctl restart kubelet

wait_api || {
  echo "API server did not recover after staging insecure settings" >&2
  exit 1
}
