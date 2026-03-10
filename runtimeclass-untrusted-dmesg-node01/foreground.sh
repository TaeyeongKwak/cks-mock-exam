#!/bin/bash
set -euo pipefail

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
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

install_runsc_on_node01() {
  if ssh ${SSH_OPTS} node01 "command -v runsc >/dev/null 2>&1 && command -v containerd-shim-runsc-v1 >/dev/null 2>&1"; then
    return 0
  fi

  ssh ${SSH_OPTS} node01 "bash -s" <<'EOF'
set -euo pipefail
tmpdir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmpdir}"
}
trap cleanup EXIT

arch="$(uname -m)"
url="https://storage.googleapis.com/gvisor/releases/release/latest/${arch}"

wget -q "${url}/runsc" -O "${tmpdir}/runsc"
wget -q "${url}/runsc.sha512" -O "${tmpdir}/runsc.sha512"
wget -q "${url}/containerd-shim-runsc-v1" -O "${tmpdir}/containerd-shim-runsc-v1"
wget -q "${url}/containerd-shim-runsc-v1.sha512" -O "${tmpdir}/containerd-shim-runsc-v1.sha512"

(
  cd "${tmpdir}"
  sha512sum -c runsc.sha512
  sha512sum -c containerd-shim-runsc-v1.sha512
)

install -m 0755 "${tmpdir}/runsc" /usr/local/bin/runsc
install -m 0755 "${tmpdir}/containerd-shim-runsc-v1" /usr/local/bin/containerd-shim-runsc-v1
EOF
}

configure_node01_containerd() {
  ssh ${SSH_OPTS} node01 "bash -s" <<'EOF'
set -euo pipefail
config="/etc/containerd/config.toml"
cp "${config}" /root/config.toml.runsc.bak

if ! grep -q 'plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc' "${config}"; then
  cat >>"${config}" <<'EOC'

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]
  runtime_type = "io.containerd.runsc.v1"
EOC
fi

systemctl restart containerd
systemctl restart kubelet
EOF
}

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

until ssh ${SSH_OPTS} node01 true >/dev/null 2>&1; do
  sleep 1
done

install_runsc_on_node01
configure_node01_containerd

wait_api || {
  echo "API server did not become ready after preparing runsc on node01" >&2
  exit 1
}
kubectl wait --for=condition=Ready node/node01 --timeout=180s >/dev/null

mkdir -p /opt/course/7
rm -f /opt/course/7/runtime-alt.yaml /opt/course/7/guestbox-dmesg.log

cat >/opt/course/7/guestbox-pod.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: guestbox
  namespace: default
spec:
  nodeName: node01
  containers:
  - name: guestbox
    image: alpine:3.18
    command: ["sh", "-c", "sleep 3600"]
EOF

kubectl delete runtimeclass sandbox-alt --ignore-not-found >/dev/null 2>&1 || true
kubectl delete pod guestbox -n default --ignore-not-found >/dev/null 2>&1 || true
