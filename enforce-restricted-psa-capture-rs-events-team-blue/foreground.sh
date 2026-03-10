#!/bin/bash
set -euo pipefail

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

until ssh ${SSH_OPTS} node01 true >/dev/null 2>&1; do
  sleep 1
done

ssh ${SSH_OPTS} node01 "mkdir -p /opt/records && rm -f /opt/records/psa-fail.log"

kubectl create namespace ops-blue --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl label namespace ops-blue \
  pod-security.kubernetes.io/enforce- \
  pod-security.kubernetes.io/enforce-version- \
  pod-security.kubernetes.io/audit- \
  pod-security.kubernetes.io/warn- \
  --overwrite >/dev/null 2>&1 || true

kubectl delete deployment debug-runner -n ops-blue --ignore-not-found >/dev/null 2>&1 || true

cat <<'EOF' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: debug-runner
  namespace: ops-blue
spec:
  replicas: 1
  selector:
    matchLabels:
      app: debug-runner
  template:
    metadata:
      labels:
        app: debug-runner
    spec:
      nodeName: controlplane
      containers:
      - name: runner
        image: busybox:1.36
        command: ["sh", "-c", "sleep 3600"]
        securityContext:
          privileged: true
EOF

kubectl rollout status deployment/debug-runner -n ops-blue --timeout=180s >/dev/null
