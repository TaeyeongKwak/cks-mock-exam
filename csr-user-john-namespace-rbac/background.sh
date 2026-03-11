#!/bin/bash
set -euo pipefail

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

mkdir -p /srv/cert-lab

kubectl create namespace tenant-user --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete csr marie-access --ignore-not-found >/dev/null 2>&1 || true
kubectl delete role tenant-editor -n tenant-user --ignore-not-found >/dev/null 2>&1 || true
kubectl delete rolebinding tenant-editor-bind -n tenant-user --ignore-not-found >/dev/null 2>&1 || true

rm -f /srv/cert-lab/marie.key /srv/cert-lab/marie.csr /srv/cert-lab/marie.crt /srv/cert-lab/marie-access.yaml /srv/cert-lab/marie.kubeconfig

cat >/srv/cert-lab/README.txt <<'EOF'
Suggested artifact paths:
- Private key: /srv/cert-lab/marie.key
- CSR file: /srv/cert-lab/marie.csr
- Kubernetes CSR manifest: /srv/cert-lab/marie-access.yaml
- Signed certificate: /srv/cert-lab/marie.crt
- Optional kubeconfig: /srv/cert-lab/marie.kubeconfig
EOF
