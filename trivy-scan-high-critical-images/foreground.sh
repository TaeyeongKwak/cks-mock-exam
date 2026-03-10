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

  arch="$(uname -m)"
  case "${arch}" in
    x86_64) asset_arch="64bit" ;;
    aarch64) asset_arch="ARM64" ;;
    *)
      echo "Unsupported architecture: ${arch}" >&2
      exit 1
      ;;
  esac

  archive="trivy_${TRIVY_VERSION}_Linux-${asset_arch}.tar.gz"
  url="https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/${archive}"

  curl -fsSL "${url}" -o "${TMP_DIR}/${archive}"
  tar -xzf "${TMP_DIR}/${archive}" -C "${TMP_DIR}" trivy
  install -m 0755 "${TMP_DIR}/trivy" /usr/local/bin/trivy
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
