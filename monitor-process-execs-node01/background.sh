#!/bin/bash
set -euo pipefail

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

until ssh ${SSH_OPTS} node01 true >/dev/null 2>&1; do
  sleep 1
done

ssh ${SSH_OPTS} node01 "export DEBIAN_FRONTEND=noninteractive; apt-get update -y >/dev/null && apt-get install -y curl >/dev/null"
ssh ${SSH_OPTS} node01 "if ! command -v falco >/dev/null 2>&1; then curl -fsSL https://falco.org/script/install | bash >/dev/null 2>&1; apt-get install -y falco >/dev/null; fi"
ssh ${SSH_OPTS} node01 "mkdir -p /opt/node-01/reports && rm -f /opt/node-01/reports/events"

kubectl create namespace proc-watch --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete deployment root-spawner uid1001-spawner uid1002-spawner -n proc-watch --ignore-not-found >/dev/null 2>&1 || true

cat <<'EOF' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: root-spawner
  namespace: proc-watch
spec:
  replicas: 1
  selector:
    matchLabels:
      app: root-spawner
  template:
    metadata:
      labels:
        app: root-spawner
    spec:
      nodeName: node01
      containers:
      - name: root-spawner
        image: busybox:1.36
        command:
        - sh
        - -c
        - |
          while true; do
            sh -c "sleep 1" >/dev/null 2>&1
            sleep 7
          done
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: uid1001-spawner
  namespace: proc-watch
spec:
  replicas: 1
  selector:
    matchLabels:
      app: uid1001-spawner
  template:
    metadata:
      labels:
        app: uid1001-spawner
    spec:
      nodeName: node01
      securityContext:
        runAsUser: 1001
      containers:
      - name: uid1001-spawner
        image: busybox:1.36
        command:
        - sh
        - -c
        - |
          while true; do
            sleep 2
            sleep 6
          done
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: uid1002-spawner
  namespace: proc-watch
spec:
  replicas: 1
  selector:
    matchLabels:
      app: uid1002-spawner
  template:
    metadata:
      labels:
        app: uid1002-spawner
    spec:
      nodeName: node01
      securityContext:
        runAsUser: 1002
      containers:
      - name: uid1002-spawner
        image: busybox:1.36
        command:
        - sh
        - -c
        - |
          while true; do
            wget -q -O- http://127.0.0.1:1 >/dev/null 2>&1 || true
            sleep 8
          done
EOF

kubectl rollout status deployment/root-spawner -n proc-watch --timeout=180s >/dev/null
kubectl rollout status deployment/uid1001-spawner -n proc-watch --timeout=180s >/dev/null
kubectl rollout status deployment/uid1002-spawner -n proc-watch --timeout=180s >/dev/null
