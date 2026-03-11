#!/bin/bash
set -euo pipefail

KUBECONFIG="/etc/kubernetes/admin.conf"
CONTAINERD_CONFIG="/etc/containerd/config.toml"

wait_api() {
  for _ in $(seq 1 90); do
    if kubectl --kubeconfig="${KUBECONFIG}" get --raw /readyz >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  return 1
}

install_runsc() {
  if command -v runsc >/dev/null 2>&1 && command -v containerd-shim-runsc-v1 >/dev/null 2>&1; then
    return 0
  fi

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

  trap - EXIT
  cleanup
}

configure_containerd() {
  cp "${CONTAINERD_CONFIG}" /root/config.toml.runsc.bak

  if ! grep -q 'plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc' "${CONTAINERD_CONFIG}"; then
    cat >>"${CONTAINERD_CONFIG}" <<'EOF'

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]
  runtime_type = "io.containerd.runsc.v1"
EOF
  fi

  systemctl restart containerd
  systemctl restart kubelet
}

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

install_runsc
configure_containerd

wait_api || {
  echo "API server did not become ready after preparing runsc" >&2
  exit 1
}

mkdir -p /root/10
rm -f /root/10/isolated-class.yaml

cat >/root/10/backend-pods.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: svc-a
  namespace: backend
spec:
  nodeName: controlplane
  containers:
  - name: svc-a
    image: registry.k8s.io/pause:3.9
---
apiVersion: v1
kind: Pod
metadata:
  name: svc-b
  namespace: backend
spec:
  nodeName: controlplane
  containers:
  - name: svc-b
    image: registry.k8s.io/pause:3.9
EOF

kubectl create namespace backend --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete runtimeclass isolated --ignore-not-found >/dev/null 2>&1 || true
kubectl delete pod svc-a svc-b -n backend --ignore-not-found >/dev/null 2>&1 || true
kubectl apply -f /root/10/backend-pods.yaml >/dev/null
kubectl wait --for=condition=Ready pod/svc-a pod/svc-b -n backend --timeout=180s >/dev/null
