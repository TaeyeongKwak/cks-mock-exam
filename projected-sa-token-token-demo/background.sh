#!/bin/bash
set -euo pipefail

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

kubectl patch serviceaccount default -n default --type merge -p '{"automountServiceAccountToken":true}' >/dev/null

cat <<'EOF' >/root/jwt-demo.yaml
apiVersion: v1
kind: Pod
metadata:
  name: jwt-demo
  namespace: default
spec:
  serviceAccountName: default
  containers:
  - name: app
    image: busybox:1.36
    command:
    - sh
    - -c
    - sleep 3600
EOF

kubectl delete pod jwt-demo -n default --ignore-not-found >/dev/null
kubectl apply -f /root/jwt-demo.yaml >/dev/null
kubectl wait --for=condition=Ready pod/jwt-demo -n default --timeout=180s >/dev/null
