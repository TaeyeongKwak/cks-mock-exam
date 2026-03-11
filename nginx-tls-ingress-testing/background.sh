#!/bin/bash
set -euo pipefail

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

mkdir -p /opt/course/10

kubectl create namespace testing-lab --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete ingress bingo-ingress -n testing-lab --ignore-not-found >/dev/null 2>&1 || true
kubectl delete service web-service -n testing-lab --ignore-not-found >/dev/null 2>&1 || true
kubectl delete pod web-pod -n testing-lab --ignore-not-found >/dev/null 2>&1 || true
kubectl delete secret bingo-tls -n testing-lab --ignore-not-found >/dev/null 2>&1 || true

openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout /opt/course/10/bingo.key \
  -out /opt/course/10/bingo.crt \
  -days 365 \
  -subj "/CN=bingo.com" >/dev/null 2>&1
