#!/bin/bash
set -euo pipefail

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

kubectl create namespace runtime-lab --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl create namespace falco --dry-run=client -o yaml | kubectl apply -f - >/dev/null

kubectl delete deployment mem-reader api-safe -n runtime-lab --ignore-not-found >/dev/null 2>&1 || true
kubectl delete pod falco -n falco --ignore-not-found >/dev/null 2>&1 || true
kubectl delete configmap falco-rules falco-config -n falco --ignore-not-found >/dev/null 2>&1 || true

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
        command:
        - sh
        - -c
        - |
          sleep 30
          while true; do
            dd if=/dev/mem of=/dev/null bs=1 count=1 >/dev/null 2>&1 || true
            sleep 60
          done
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
  name: falco-rules
  namespace: falco
data:
  falco_rules.local.yaml: |
    - rule: Detect Dev Mem Access
      desc: Detect attempts to read or write /dev/mem from a container
      condition: container and fd.name=/dev/mem
      output: "Access to /dev/mem detected | deployment=mem-reader file=%fd.name container=%container.name"
      priority: WARNING
      tags: [filesystem, container]
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: falco-config
  namespace: falco
data:
  falco.yaml: |
    rules_file:
      - /etc/falco/falco_rules.yaml
      - /etc/falco/falco_rules.local.yaml
    stdout_output:
      enabled: true
    syslog_output:
      enabled: false
    file_output:
      enabled: false
    grpc:
      enabled: false
    grpc_output:
      enabled: false
---
apiVersion: v1
kind: Pod
metadata:
  name: falco
  namespace: falco
  labels:
    app: falco
spec:
  restartPolicy: Always
  serviceAccountName: default
  hostNetwork: true
  hostPID: true
  containers:
  - name: falco
    image: falcosecurity/falco:0.37.1
    securityContext:
      privileged: true
    args:
      - /usr/bin/falco
      - --userspace
      - -c
      - /etc/falco/falco.yaml
      - -r
      - /etc/falco/falco_rules.local.yaml
    volumeMounts:
      - name: dev-fs
        mountPath: /host/dev
        readOnly: true
      - name: proc-fs
        mountPath: /host/proc
        readOnly: true
      - name: boot-fs
        mountPath: /host/boot
        readOnly: true
      - name: lib-modules
        mountPath: /host/lib/modules
        readOnly: true
      - name: usr-src
        mountPath: /host/usr/src
        readOnly: true
      - name: falco-config
        mountPath: /etc/falco/falco.yaml
        subPath: falco.yaml
      - name: falco-rules
        mountPath: /etc/falco/falco_rules.local.yaml
        subPath: falco_rules.local.yaml
  volumes:
    - name: dev-fs
      hostPath:
        path: /dev
    - name: proc-fs
      hostPath:
        path: /proc
    - name: boot-fs
      hostPath:
        path: /boot
    - name: lib-modules
      hostPath:
        path: /lib/modules
    - name: usr-src
      hostPath:
        path: /usr/src
    - name: falco-config
      configMap:
        name: falco-config
    - name: falco-rules
      configMap:
        name: falco-rules
EOF

kubectl rollout status deployment/mem-reader -n runtime-lab --timeout=180s >/dev/null
kubectl rollout status deployment/api-safe -n runtime-lab --timeout=180s >/dev/null
kubectl wait --for=condition=Ready pod/falco -n falco --timeout=180s >/dev/null

for _ in $(seq 1 30); do
  if kubectl logs -n falco pod/falco -c falco 2>/dev/null | grep -q 'file=/dev/mem'; then
    exit 0
  fi
  sleep 5
done

echo "Falco did not record the staged /dev/mem event in time" >&2
exit 1
