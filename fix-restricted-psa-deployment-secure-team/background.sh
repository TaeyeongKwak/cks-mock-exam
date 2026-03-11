#!/bin/bash
set -euo pipefail

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

mkdir -p /root/masters

kubectl create namespace secure-lab --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl label namespace secure-lab \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/enforce-version=latest \
  --overwrite >/dev/null

kubectl delete deployment policy-app -n secure-lab --ignore-not-found >/dev/null 2>&1 || true

cat >/root/masters/restricted-fix.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: policy-app
  namespace: secure-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: policy-app
  template:
    metadata:
      labels:
        app: policy-app
    spec:
      containers:
      - name: app
        image: busybox:1.36
        command: ["sh", "-c", "sleep 3600"]
        securityContext:
          allowPrivilegeEscalation: true
          runAsUser: 0
          capabilities:
            add: ["NET_ADMIN"]
EOF
