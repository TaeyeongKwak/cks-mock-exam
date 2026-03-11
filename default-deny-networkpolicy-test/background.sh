#!/bin/bash
set -euo pipefail

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

mkdir -p /root/policy-lab

kubectl create namespace vault --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete networkpolicy blanket-policy -n vault --ignore-not-found >/dev/null 2>&1 || true

cat >/root/policy-lab/blanket-policy.yaml <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: blanket-policy
EOF
