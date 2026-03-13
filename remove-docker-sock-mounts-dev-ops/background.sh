#!/bin/bash
set -euo pipefail

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

mkdir -p /var/run
rm -rf /var/run/docker.sock
touch /var/run/docker.sock

kubectl create namespace build-ops --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete deployment job-runner image-scan api-gateway -n build-ops --ignore-not-found >/dev/null 2>&1 || true

cat >/root/build-ops-workloads.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: job-runner
  namespace: build-ops
spec:
  replicas: 1
  selector:
    matchLabels:
      app: job-runner
  template:
    metadata:
      labels:
        app: job-runner
    spec:
      nodeName: controlplane
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
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: image-scan
  namespace: build-ops
spec:
  replicas: 1
  selector:
    matchLabels:
      app: image-scan
  template:
    metadata:
      labels:
        app: image-scan
    spec:
      nodeName: controlplane
      containers:
      - name: auditor
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
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  namespace: build-ops
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api-gateway
  template:
    metadata:
      labels:
        app: api-gateway
    spec:
      nodeName: controlplane
      containers:
      - name: api
        image: busybox:1.36
        command: ["sh", "-c", "sleep 3600"]
EOF

kubectl apply -f /root/build-ops-workloads.yaml >/dev/null
kubectl rollout status deployment/job-runner -n build-ops --timeout=180s >/dev/null
kubectl rollout status deployment/image-scan -n build-ops --timeout=180s >/dev/null
kubectl rollout status deployment/api-gateway -n build-ops --timeout=180s >/dev/null
