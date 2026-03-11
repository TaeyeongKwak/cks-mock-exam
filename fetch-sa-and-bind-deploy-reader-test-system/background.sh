#!/bin/bash
set -euo pipefail

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

mkdir -p /candidate
rm -f /candidate/current-sa.txt

kubectl delete namespace qa-system --ignore-not-found >/dev/null 2>&1 || true
while kubectl get namespace qa-system >/dev/null 2>&1; do
  sleep 2
done

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: qa-system
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: workload-inspector
  namespace: qa-system
---
apiVersion: v1
kind: Pod
metadata:
  name: web-pod
  namespace: qa-system
spec:
  serviceAccountName: workload-inspector
  containers:
  - name: nginx
    image: registry.k8s.io/pause:3.9
EOF

kubectl wait -n qa-system --for=condition=Ready pod/web-pod --timeout=180s >/dev/null
