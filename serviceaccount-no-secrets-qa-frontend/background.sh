#!/bin/bash
set -euo pipefail

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

kubectl create namespace qa-lab --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete pod frontend-ui -n qa-lab --ignore-not-found >/dev/null 2>&1 || true
kubectl delete serviceaccount backend-team -n qa-lab --ignore-not-found >/dev/null 2>&1 || true
kubectl delete secret qa-api-key -n qa-lab --ignore-not-found >/dev/null 2>&1 || true

kubectl create secret generic qa-api-key -n qa-lab --from-literal=token=super-secret >/dev/null

cat >/root/frontend-ui-pod.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: frontend-ui
  namespace: qa-lab
spec:
  serviceAccountName: default
  nodeName: controlplane
  containers:
  - name: frontend
    image: busybox:1.36
    command: ["sh", "-c", "sleep 3600"]
EOF

kubectl apply -f /root/frontend-ui-pod.yaml >/dev/null
kubectl wait --for=condition=Ready pod/frontend-ui -n qa-lab --timeout=180s >/dev/null
