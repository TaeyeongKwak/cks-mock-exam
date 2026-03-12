#!/bin/bash
set -euo pipefail

TRIVY_VERSION="0.57.1"
TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

install_trivy() {
  if command -v trivy >/dev/null 2>&1; then
    return 0
  fi

  export DEBIAN_FRONTEND=noninteractive
  apt-get update >/dev/null
  apt-get install -y wget gnupg lsb-release apt-transport-https >/dev/null

  wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
    | gpg --dearmor -o /usr/share/keyrings/trivy.gpg

  echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" \
    >/etc/apt/sources.list.d/trivy.list

  apt-get update >/dev/null
  apt-get install -y "trivy=${TRIVY_VERSION}" >/dev/null || apt-get install -y trivy >/dev/null

  command -v trivy >/dev/null 2>&1 || {
    echo "trivy installation failed" >&2
    exit 1
  }
}

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

install_trivy

kubectl create namespace atlas --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete pod web-legacy db-legacy platform-core -n atlas --ignore-not-found >/dev/null 2>&1 || true

cat >/root/atlas-pods.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: web-legacy
  namespace: atlas
spec:
  nodeName: controlplane
  containers:
  - name: web
    image: httpd:2.4.49
---
apiVersion: v1
kind: Pod
metadata:
  name: db-legacy
  namespace: atlas
spec:
  nodeName: controlplane
  containers:
  - name: db
    image: postgres:12
---
apiVersion: v1
kind: Pod
metadata:
  name: platform-core
  namespace: atlas
spec:
  nodeName: controlplane
  containers:
  - name: pause
    image: registry.k8s.io/pause:3.9
EOF

kubectl apply -f /root/atlas-pods.yaml >/dev/null
kubectl wait --for=condition=Ready pod/web-legacy -n atlas --timeout=180s >/dev/null
kubectl wait --for=condition=Ready pod/db-legacy -n atlas --timeout=180s >/dev/null
kubectl wait --for=condition=Ready pod/platform-core -n atlas --timeout=180s >/dev/null

kubectl get pods -n atlas -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.containers[0].image}{"\n"}{end}' | sort >/opt/atlas-pod-images.txt
rm -f /opt/atlas-trivy-report.txt

: >/opt/.atlas-expected-severe-pods.txt
: >/opt/.atlas-expected-safe-pods.txt

while read -r pod image; do
  [ -n "${pod:-}" ] || continue
  report_path="${TMP_DIR}/${pod}.json"
  trivy image --quiet --severity HIGH,CRITICAL --format json -o "${report_path}" "${image}" >/dev/null

  if REPORT_PATH="${report_path}" python3 - <<'PY'
import json
import os
import sys

with open(os.environ["REPORT_PATH"], "r", encoding="utf-8") as fh:
    data = json.load(fh)

for result in data.get("Results", []) or []:
    if result.get("Vulnerabilities"):
        sys.exit(0)
sys.exit(1)
PY
  then
    echo "${pod}" >>/opt/.atlas-expected-severe-pods.txt
  else
    echo "${pod}" >>/opt/.atlas-expected-safe-pods.txt
  fi
done </opt/atlas-pod-images.txt

sort -u -o /opt/.atlas-expected-severe-pods.txt /opt/.atlas-expected-severe-pods.txt
sort -u -o /opt/.atlas-expected-safe-pods.txt /opt/.atlas-expected-safe-pods.txt
