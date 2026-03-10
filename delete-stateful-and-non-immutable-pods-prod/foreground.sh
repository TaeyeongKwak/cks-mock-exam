#!/bin/bash
set -euo pipefail

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

kubectl create namespace shipping --dry-run=client -o yaml | kubectl apply -f - >/dev/null

kubectl delete pod ledger-api metrics-sidecar scratch-cache ops-console report-exporter -n shipping --ignore-not-found >/dev/null 2>&1 || true

cat <<'EOF' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Pod
metadata:
  name: ledger-api
  namespace: shipping
  labels:
    lab.cleanup: keep
spec:
  containers:
  - name: app
    image: registry.k8s.io/pause:3.9
    securityContext:
      privileged: false
      readOnlyRootFilesystem: true
---
apiVersion: v1
kind: Pod
metadata:
  name: metrics-sidecar
  namespace: shipping
  labels:
    lab.cleanup: keep
spec:
  containers:
  - name: agent
    image: registry.k8s.io/pause:3.9
    securityContext:
      privileged: false
      readOnlyRootFilesystem: true
---
apiVersion: v1
kind: Pod
metadata:
  name: scratch-cache
  namespace: shipping
  labels:
    lab.cleanup: remove
spec:
  containers:
  - name: cache
    image: registry.k8s.io/pause:3.9
    volumeMounts:
    - name: scratch
      mountPath: /var/cache/app
    securityContext:
      privileged: false
      readOnlyRootFilesystem: true
  volumes:
  - name: scratch
    emptyDir: {}
---
apiVersion: v1
kind: Pod
metadata:
  name: ops-console
  namespace: shipping
  labels:
    lab.cleanup: remove
spec:
  containers:
  - name: shell
    image: registry.k8s.io/pause:3.9
    securityContext:
      privileged: true
      readOnlyRootFilesystem: true
---
apiVersion: v1
kind: Pod
metadata:
  name: report-exporter
  namespace: shipping
  labels:
    lab.cleanup: remove
spec:
  containers:
  - name: writer
    image: registry.k8s.io/pause:3.9
    securityContext:
      privileged: false
      readOnlyRootFilesystem: false
EOF

kubectl wait --for=condition=Ready pod/ledger-api pod/metrics-sidecar pod/scratch-cache pod/ops-console pod/report-exporter -n shipping --timeout=180s >/dev/null
