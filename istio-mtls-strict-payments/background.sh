#!/bin/bash
set -euo pipefail

KUBECONFIG="/etc/kubernetes/admin.conf"
ISTIO_VERSION="1.28.3"
ISTIO_DIR="/root/istio-${ISTIO_VERSION}"

wait_api() {
  for _ in $(seq 1 120); do
    if kubectl --kubeconfig="${KUBECONFIG}" get --raw /readyz >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  return 1
}

install_istio() {
  if command -v istioctl >/dev/null 2>&1; then
    return 0
  fi

  if [ ! -d "${ISTIO_DIR}" ]; then
    curl -L https://istio.io/downloadIstio | ISTIO_VERSION="${ISTIO_VERSION}" TARGET_ARCH=x86_64 sh -
  fi

  install -m 0755 "${ISTIO_DIR}/bin/istioctl" /usr/local/bin/istioctl
}

setup_mesh() {
  if ! kubectl get namespace istio-system >/dev/null 2>&1; then
    istioctl install -y --set profile=minimal
  fi

  kubectl patch deployment istiod -n istio-system --type='strategic' -p '{
    "spec": {
      "template": {
        "spec": {
          "tolerations": [
            {
              "key": "node-role.kubernetes.io/control-plane",
              "operator": "Exists",
              "effect": "NoSchedule"
            }
          ],
          "containers": [
            {
              "name": "discovery",
              "resources": {
                "requests": {
                  "cpu": "100m",
                  "memory": "256Mi"
                },
                "limits": {
                  "cpu": "500m",
                  "memory": "512Mi"
                }
              }
            }
          ]
        }
      }
    }
  }' >/dev/null

  kubectl rollout status deployment/istiod -n istio-system --timeout=300s >/dev/null
}

deploy_workloads() {
  kubectl create namespace billing --dry-run=client -o yaml | kubectl apply -f - >/dev/null
  kubectl label namespace billing istio-injection=enabled --overwrite >/dev/null

  kubectl delete peerauthentication default -n billing --ignore-not-found >/dev/null 2>&1 || true
  kubectl delete deployment httpbin curl -n billing --ignore-not-found >/dev/null 2>&1 || true
  kubectl delete service httpbin -n billing --ignore-not-found >/dev/null 2>&1 || true

  cat >/root/payments-workloads.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin
  namespace: billing
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpbin
  template:
    metadata:
      labels:
        app: httpbin
    spec:
      containers:
      - name: httpbin
        image: docker.io/kennethreitz/httpbin
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  namespace: billing
spec:
  selector:
    app: httpbin
  ports:
  - name: http
    port: 8000
    targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: curl
  namespace: billing
spec:
  replicas: 1
  selector:
    matchLabels:
      app: curl
  template:
    metadata:
      labels:
        app: curl
    spec:
      containers:
      - name: curl
        image: curlimages/curl:8.8.0
        command: ["sleep", "3650d"]
EOF

  kubectl apply -f /root/payments-workloads.yaml >/dev/null
  kubectl rollout status deployment/httpbin -n billing --timeout=300s >/dev/null
  kubectl rollout status deployment/curl -n billing --timeout=300s >/dev/null
}

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null
wait_api
install_istio
setup_mesh
deploy_workloads
rm -f /root/billing-peerauth.yaml
