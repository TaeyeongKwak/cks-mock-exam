#!/bin/bash
set -euo pipefail

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

mkdir -p /root/sandbox
touch /var/run/docker.sock
chmod 0666 /var/run/docker.sock

kubectl create namespace sandbox-lab --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete deployment docker-ops -n sandbox-lab --ignore-not-found >/dev/null 2>&1 || true

cat >/root/sandbox/docker-ops.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: docker-ops
  namespace: sandbox-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: docker-ops
  template:
    metadata:
      labels:
        app: docker-ops
    spec:
      containers:
      - name: toolbox
        image: busybox:1.36
        command: ["sh", "-c", "sleep 3600"]
        securityContext:
          runAsUser: 0
          allowPrivilegeEscalation: true
          capabilities:
            add: ["NET_ADMIN", "SYS_ADMIN"]
        volumeMounts:
        - name: docker-sock
          mountPath: /var/run/docker.sock
      volumes:
      - name: docker-sock
        hostPath:
          path: /var/run/docker.sock
          type: File
EOF

kubectl apply -f /root/sandbox/docker-ops.yaml >/dev/null
kubectl rollout status deployment/docker-ops -n sandbox-lab --timeout=180s >/dev/null
