#!/bin/bash
set -euo pipefail

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

for ns in app-team qa-lab misc-team; do
  kubectl create namespace "${ns}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
done

kubectl delete networkpolicy ingress-guard -n app-team --ignore-not-found >/dev/null 2>&1 || true
kubectl delete pod catalog-service frontend same-ns-client testing-client denied-client -n app-team --ignore-not-found >/dev/null 2>&1 || true
kubectl delete pod testing-client -n qa-lab --ignore-not-found >/dev/null 2>&1 || true
kubectl delete pod denied-client -n misc-team --ignore-not-found >/dev/null 2>&1 || true

cat <<'EOF' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Pod
metadata:
  name: catalog-service
  namespace: app-team
  labels:
    app: catalog-service
spec:
  containers:
  - name: catalog-service
    image: hashicorp/http-echo:1.0.0
    args: ["-text=products-ok"]
    ports:
    - containerPort: 5678
---
apiVersion: v1
kind: Pod
metadata:
  name: same-ns-client
  namespace: app-team
  labels:
    app: same-ns-client
spec:
  containers:
  - name: client
    image: busybox:1.36
    command: ["sh", "-c", "sleep 3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: testing-client
  namespace: qa-lab
  labels:
    app: testing-client
    environment: testing
spec:
  containers:
  - name: client
    image: busybox:1.36
    command: ["sh", "-c", "sleep 3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: denied-client
  namespace: misc-team
  labels:
    app: denied-client
spec:
  containers:
  - name: client
    image: busybox:1.36
    command: ["sh", "-c", "sleep 3600"]
EOF

kubectl wait --for=condition=Ready pod/catalog-service pod/same-ns-client -n app-team --timeout=180s >/dev/null
kubectl wait --for=condition=Ready pod/testing-client -n qa-lab --timeout=180s >/dev/null
kubectl wait --for=condition=Ready pod/denied-client -n misc-team --timeout=180s >/dev/null
