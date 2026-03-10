#!/bin/bash
set -euo pipefail

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

kubectl create namespace runtime-lab --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl create namespace falco --dry-run=client -o yaml | kubectl apply -f - >/dev/null

kubectl delete deployment mem-reader api-safe -n runtime-lab --ignore-not-found >/dev/null 2>&1 || true
kubectl delete deployment falco-monitor -n falco --ignore-not-found >/dev/null 2>&1 || true
kubectl delete configmap falco-alerts -n falco --ignore-not-found >/dev/null 2>&1 || true

cat <<'EOF' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mem-reader
  namespace: runtime-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mem-reader
  template:
    metadata:
      labels:
        app: mem-reader
    spec:
      nodeName: controlplane
      containers:
      - name: probe
        image: busybox:1.36
        command: ["sh", "-c", "sleep 3600"]
        volumeMounts:
        - name: devmem
          mountPath: /dev/mem
        securityContext:
          privileged: true
      volumes:
      - name: devmem
        hostPath:
          path: /dev/mem
          type: CharDevice
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-safe
  namespace: runtime-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api-safe
  template:
    metadata:
      labels:
        app: api-safe
    spec:
      nodeName: controlplane
      containers:
      - name: api
        image: busybox:1.36
        command: ["sh", "-c", "sleep 3600"]
EOF

cat <<'EOF' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: falco-alerts
  namespace: falco
data:
  falco.log: |
    10:15:11.000000000: Warning Access to /dev/mem detected | priority=Warning rule=Direct Device Memory Access container=probe k8s.ns.name=runtime-lab k8s.pod.name=mem-reader-7d5f8f9d4f-abcde deployment=mem-reader file=/dev/mem
    10:15:12.000000000: Notice Regular process activity | priority=Notice rule=Terminal shell in container container=api k8s.ns.name=runtime-lab k8s.pod.name=api-safe-6b7cc69b9f-fghij deployment=api-safe
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: falco-monitor
  namespace: falco
spec:
  replicas: 1
  selector:
    matchLabels:
      app: falco-monitor
  template:
    metadata:
      labels:
        app: falco-monitor
    spec:
      containers:
      - name: falco
        image: busybox:1.36
        command: ["sh", "-c", "cat /var/log/falco/falco.log; sleep 3600"]
        volumeMounts:
        - name: alerts
          mountPath: /var/log/falco
      volumes:
      - name: alerts
        configMap:
          name: falco-alerts
EOF

kubectl rollout status deployment/mem-reader -n runtime-lab --timeout=180s >/dev/null
kubectl rollout status deployment/api-safe -n runtime-lab --timeout=180s >/dev/null
kubectl rollout status deployment/falco-monitor -n falco --timeout=180s >/dev/null
