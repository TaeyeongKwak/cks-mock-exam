#!/bin/bash
set -euo pipefail

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

mkdir -p /root/policy-lab

kubectl delete validatingadmissionpolicybinding prevent-privileged-binding --ignore-not-found >/dev/null 2>&1 || true
kubectl delete validatingadmissionpolicy prevent-privileged-policy --ignore-not-found >/dev/null 2>&1 || true
kubectl delete clusterrolebinding prevent-role-binding --ignore-not-found >/dev/null 2>&1 || true
kubectl delete clusterrole prevent-role --ignore-not-found >/dev/null 2>&1 || true
kubectl delete serviceaccount psp-sa -n policy-lab --ignore-not-found >/dev/null 2>&1 || true
kubectl delete pod privileged-check nonprivileged-check -n policy-lab --ignore-not-found >/dev/null 2>&1 || true
kubectl create namespace policy-lab --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat >/root/policy-lab/privileged-pod.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: privileged-check
  namespace: policy-lab
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c", "sleep 3600"]
    securityContext:
      privileged: true
EOF

cat >/root/policy-lab/non-privileged-pod.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: nonprivileged-check
  namespace: policy-lab
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c", "sleep 3600"]
EOF
