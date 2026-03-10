#!/bin/bash
set -euo pipefail

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

mkdir -p /var/run
touch /var/run/docker.sock
chown root:123 /var/run/docker.sock
chmod 0660 /var/run/docker.sock

kubectl create namespace ci-ops --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete deployment ci-runner -n ci-ops --ignore-not-found >/dev/null 2>&1 || true

cat >/root/ci-ops-deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ci-runner
  namespace: ci-ops
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ci-runner
  template:
    metadata:
      labels:
        app: ci-runner
    spec:
      nodeName: controlplane
      securityContext:
        runAsUser: 1000
        runAsGroup: 1000
        supplementalGroups:
        - 123
      containers:
      - name: runner
        image: busybox:1.36
        command: ["sh", "-c", "sleep 3600"]
        volumeMounts:
        - name: docker-sock
          mountPath: /var/run/docker.sock
      volumes:
      - name: docker-sock
        hostPath:
          path: /var/run/docker.sock
          type: File
EOF

kubectl apply -f /root/ci-ops-deployment.yaml >/dev/null
kubectl rollout status deployment/ci-runner -n ci-ops --timeout=180s >/dev/null
