#!/bin/bash
set -euo pipefail

TRIVY_VERSION="0.57.1"
TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

install_trivy() {
  if command -v trivy >/dev/null 2>&1; then
    return 0
  fi
  export DEBIAN_FRONTEND=noninteractive
  apt-get update >/dev/null
  apt-get install -y wget gnupg lsb-release apt-transport-https >/dev/null

  wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
    | gpg --dearmor -o /usr/share/keyrings/trivy.gpg

  echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" \
    >/etc/apt/sources.list.d/trivy.list

  apt-get update >/dev/null
  apt-get install -y "trivy=${TRIVY_VERSION}" >/dev/null || apt-get install -y trivy >/dev/null

  command -v trivy >/dev/null 2>&1 || {
    echo "trivy installation failed" >&2
    exit 1
  }
}

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

install_trivy

cat >/opt/scan-images.txt <<'EOF'
ubuntu:18.04
registry.k8s.io/kube-apiserver:v1.24.0
registry.k8s.io/kube-scheduler:v1.23.0
postgres:12
httpd:2.4.49
EOF

rm -f /opt/scan-high-critical.txt
