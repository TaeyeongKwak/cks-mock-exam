#!/bin/bash
set -euo pipefail

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

mkdir -p /root/secret-lab
rm -f /root/secret-lab/username.txt /root/secret-lab/password.txt

kubectl create namespace vault --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete secret root-admin app-secret -n vault --ignore-not-found >/dev/null 2>&1 || true
kubectl delete pod secret-mount-pod -n vault --ignore-not-found >/dev/null 2>&1 || true

kubectl create secret generic root-admin -n vault \
  --from-literal=username=clusteradmin \
  --from-literal=password=ultrasecurepass >/dev/null
