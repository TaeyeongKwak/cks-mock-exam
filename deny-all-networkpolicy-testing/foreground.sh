#!/bin/bash
set -euo pipefail

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

kubectl create namespace quarantine --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl create namespace edge --dry-run=client -o yaml | kubectl apply -f - >/dev/null

kubectl delete networkpolicy air-gap -n quarantine --ignore-not-found >/dev/null 2>&1 || true
kubectl delete pod vault-api inside-check -n quarantine --ignore-not-found >/dev/null 2>&1 || true
kubectl delete pod edge-api edge-check -n edge --ignore-not-found >/dev/null 2>&1 || true

cat <<'EOF' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Pod
metadata:
  name: vault-api
  namespace: quarantine
  labels:
    app: vault-api
spec:
  containers:
  - name: api
    image: registry.k8s.io/e2e-test-images/agnhost:2.39
    args: ["netexec", "--http-port=8080"]
---
apiVersion: v1
kind: Pod
metadata:
  name: inside-check
  namespace: quarantine
spec:
  containers:
  - name: toolbox
    image: busybox:1.36
    command: ["sh", "-c", "sleep 3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: edge-api
  namespace: edge
  labels:
    app: edge-api
spec:
  containers:
  - name: api
    image: registry.k8s.io/e2e-test-images/agnhost:2.39
    args: ["netexec", "--http-port=8080"]
---
apiVersion: v1
kind: Pod
metadata:
  name: edge-check
  namespace: edge
spec:
  containers:
  - name: toolbox
    image: busybox:1.36
    command: ["sh", "-c", "sleep 3600"]
EOF

kubectl wait --for=condition=Ready pod/vault-api pod/inside-check -n quarantine --timeout=180s >/dev/null
kubectl wait --for=condition=Ready pod/edge-api pod/edge-check -n edge --timeout=180s >/dev/null
