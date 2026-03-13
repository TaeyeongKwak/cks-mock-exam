#!/bin/bash
set -euo pipefail

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

mkdir -p /var/run
rm -rf /var/run/docker.sock
touch /var/run/docker.sock
chown root:123 /var/run/docker.sock
chmod 0660 /var/run/docker.sock

kubectl create namespace ci-sec --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete deployment build-runner -n ci-sec --ignore-not-found >/dev/null 2>&1 || true

cat >/root/build-runner.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: build-runner
  namespace: ci-sec
spec:
  replicas: 1
  selector:
    matchLabels:
      app: build-runner
  template:
    metadata:
      labels:
        app: build-runner
    spec:
      nodeName: controlplane
      securityContext:
        supplementalGroups:
        - 123
      containers:
      - name: builder
        image: busybox:1.36
        command: ["sh", "-c", "sleep 3600"]
        securityContext:
          runAsUser: 1000
          runAsGroup: 1000
        volumeMounts:
        - name: docker-sock
          mountPath: /var/run/docker.sock
      - name: observer
        image: busybox:1.36
        command: ["sh", "-c", "sleep 3600"]
        securityContext:
          runAsUser: 2000
          runAsGroup: 2000
        volumeMounts:
        - name: docker-sock
          mountPath: /var/run/docker.sock
      volumes:
      - name: docker-sock
        hostPath:
          path: /var/run/docker.sock
          type: File
EOF

kubectl apply -f /root/build-runner.yaml >/dev/null
kubectl rollout status deployment/build-runner -n ci-sec --timeout=180s >/dev/null
