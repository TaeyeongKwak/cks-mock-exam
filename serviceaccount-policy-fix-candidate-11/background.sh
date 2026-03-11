#!/bin/bash
set -euo pipefail

TARGET_DIR="/home/candidate/11"

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

mkdir -p "${TARGET_DIR}"

kubectl create namespace qa-lab --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete pod frontend-ui -n qa-lab --ignore-not-found >/dev/null 2>&1 || true
kubectl delete serviceaccount ui-sa frontend qa-helper legacy-builder -n qa-lab --ignore-not-found >/dev/null 2>&1 || true

kubectl create serviceaccount frontend -n qa-lab >/dev/null
kubectl create serviceaccount qa-helper -n qa-lab >/dev/null
kubectl create serviceaccount legacy-builder -n qa-lab >/dev/null

cat >"${TARGET_DIR}/ui-pod.yaml" <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: frontend-ui
  namespace: qa-lab
spec:
  serviceAccountName: broken-account
  nodeName: controlplane
  containers:
  - name: frontend
    image: nginx:1.27
EOF
