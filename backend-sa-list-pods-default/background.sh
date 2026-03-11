#!/bin/bash
set -euo pipefail

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

kubectl delete pod inventory-shell -n default --ignore-not-found >/dev/null 2>&1 || true
kubectl delete serviceaccount viewer-sa -n default --ignore-not-found >/dev/null 2>&1 || true
kubectl delete role pod-viewer -n default --ignore-not-found >/dev/null 2>&1 || true
kubectl delete rolebinding pod-viewer-bind -n default --ignore-not-found >/dev/null 2>&1 || true
