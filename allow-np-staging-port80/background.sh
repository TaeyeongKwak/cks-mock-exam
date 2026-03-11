#!/bin/bash
set -euo pipefail

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

kubectl create namespace tenant-a --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl create namespace tenant-b --dry-run=client -o yaml | kubectl apply -f - >/dev/null

kubectl delete networkpolicy tenant-http-only -n tenant-a --ignore-not-found >/dev/null 2>&1 || true
kubectl delete pod local-probe catalog-http catalog-admin -n tenant-a --ignore-not-found >/dev/null 2>&1 || true
kubectl delete pod remote-probe -n tenant-b --ignore-not-found >/dev/null 2>&1 || true

cat <<'EOF' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Pod
metadata:
  name: local-probe
  namespace: tenant-a
  labels:
    role: probe
spec:
  containers:
  - name: probe
    image: busybox:1.36
    command: ["sh", "-c", "sleep 3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: catalog-http
  namespace: tenant-a
  labels:
    lane: shared
spec:
  containers:
  - name: app
    image: busybox:1.36
    command:
    - sh
    - -c
    - |
      mkdir -p /srv/http
      echo tenant-a-http >/srv/http/index.html
      httpd -f -p 80 -h /srv/http
---
apiVersion: v1
kind: Pod
metadata:
  name: catalog-admin
  namespace: tenant-a
  labels:
    lane: admin
spec:
  containers:
  - name: app
    image: busybox:1.36
    command:
    - sh
    - -c
    - |
      mkdir -p /srv/http
      echo tenant-a-admin >/srv/http/index.html
      httpd -f -p 8080 -h /srv/http
---
apiVersion: v1
kind: Pod
metadata:
  name: remote-probe
  namespace: tenant-b
  labels:
    role: probe
spec:
  containers:
  - name: probe
    image: busybox:1.36
    command: ["sh", "-c", "sleep 3600"]
EOF

kubectl wait -n tenant-a --for=condition=Ready pod/local-probe pod/catalog-http pod/catalog-admin --timeout=180s >/dev/null
kubectl wait -n tenant-b --for=condition=Ready pod/remote-probe --timeout=180s >/dev/null
