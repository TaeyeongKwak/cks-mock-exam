#!/bin/bash
set -euo pipefail

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

kubectl create namespace sandbox --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete networkpolicy outbound-lock -n sandbox --ignore-not-found >/dev/null 2>&1 || true
