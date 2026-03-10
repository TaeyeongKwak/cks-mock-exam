#!/bin/bash
set -euo pipefail

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

cat >/root/web-token-pod.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: web-token-pod
  namespace: default
spec:
  containers:
  - name: nginx
    image: registry.k8s.io/e2e-test-images/nginx:1.14-4
    ports:
    - containerPort: 80
EOF

kubectl patch serviceaccount default -n default --type merge -p '{"automountServiceAccountToken":true}' >/dev/null 2>&1 || true
kubectl delete secret sa-token-custom -n default --ignore-not-found >/dev/null 2>&1 || true
kubectl delete pod web-token-pod -n default --ignore-not-found >/dev/null 2>&1 || true
kubectl apply -f /root/web-token-pod.yaml >/dev/null
kubectl wait --for=condition=Ready pod/web-token-pod -n default --timeout=180s >/dev/null
