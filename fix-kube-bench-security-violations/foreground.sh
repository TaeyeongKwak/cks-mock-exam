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

cp "${APISERVER}" /root/kube-apiserver.yaml.kubebench-review.bak
cp "${ETCD}" /root/etcd.yaml.kubebench-review.bak
cp "${KUBELET_CONFIG}" /root/kubelet-config.yaml.kubebench-review.bak

if grep -q -- '--kubelet-certificate-authority=' "${APISERVER}"; then
  sed -i 's@--kubelet-certificate-authority=.*@    - --kubelet-certificate-authority=/etc/kubernetes/pki/front-proxy-ca.crt@' "${APISERVER}"
else
  sed -i '/--kubelet-client-key=/a\    - --kubelet-certificate-authority=/etc/kubernetes/pki/front-proxy-ca.crt' "${APISERVER}"
fi

if grep -q -- '--disable-admission-plugins=' "${APISERVER}"; then
  if ! grep -q -- '--disable-admission-plugins=.*PodSecurity' "${APISERVER}"; then
    sed -i 's@--disable-admission-plugins=\(.*\)@    - --disable-admission-plugins=\1,PodSecurity@' "${APISERVER}"
  fi
else
  sed -i '/--enable-admission-plugins=/a\    - --disable-admission-plugins=PodSecurity' "${APISERVER}"
fi

python3 - <<'PY'
from pathlib import Path
path = Path("/var/lib/kubelet/config.yaml")
text = path.read_text()
if "serverTLSBootstrap:" in text:
    text = text.replace("serverTLSBootstrap: true", "serverTLSBootstrap: false")
else:
    text += '\nserverTLSBootstrap: false\n'

if "anonymous:\n    enabled: false" in text:
    text = text.replace("anonymous:\n    enabled: false", "anonymous:\n    enabled: true")
elif "anonymous:\n      enabled: false" in text:
    text = text.replace("anonymous:\n      enabled: false", "anonymous:\n      enabled: true")
else:
    text += '\nauthentication:\n  anonymous:\n    enabled: true\n'

if "authorization:\n  mode: Webhook" in text:
    text = text.replace("authorization:\n  mode: Webhook", "authorization:\n  mode: AlwaysAllow")
elif "authorization:\n    mode: Webhook" in text:
    text = text.replace("authorization:\n    mode: Webhook", "authorization:\n    mode: AlwaysAllow")
else:
    text += '\nauthorization:\n  mode: AlwaysAllow\n'

path.write_text(text)
PY

if grep -q -- '--auto-tls=' "${ETCD}"; then
  sed -i 's@--auto-tls=.*@    - --auto-tls=true@' "${ETCD}"
else
  sed -i '/--cert-file=/a\    - --auto-tls=true' "${ETCD}"
fi

if grep -q -- '--peer-auto-tls=' "${ETCD}"; then
  sed -i 's@--peer-auto-tls=.*@    - --peer-auto-tls=true@' "${ETCD}"
else
  sed -i '/--peer-cert-file=/a\    - --peer-auto-tls=true' "${ETCD}"
fi

systemctl restart kubelet

wait_api || {
  echo "API server did not recover after staging insecure settings" >&2
  exit 1
}
