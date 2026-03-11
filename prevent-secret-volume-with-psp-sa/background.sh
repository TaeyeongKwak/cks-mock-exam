#!/bin/bash
set -euo pipefail

HELPER_DIR="/root/policy-zone"

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

mkdir -p "${HELPER_DIR}"

kubectl create namespace policy-zone --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl label namespace policy-zone volume-policy=policy-zone --overwrite >/dev/null

kubectl delete serviceaccount psp-sa -n policy-zone --ignore-not-found >/dev/null 2>&1 || true
kubectl delete clusterrole psp-role --ignore-not-found >/dev/null 2>&1 || true
kubectl delete clusterrolebinding psp-role-binding --ignore-not-found >/dev/null 2>&1 || true
kubectl delete validatingadmissionpolicy prevent-volume-policy --ignore-not-found >/dev/null 2>&1 || true
kubectl delete validatingadmissionpolicybinding prevent-volume-policy-binding --ignore-not-found >/dev/null 2>&1 || true
kubectl delete secret zone-config -n policy-zone --ignore-not-found >/dev/null 2>&1 || true
kubectl delete pvc zone-data -n policy-zone --ignore-not-found >/dev/null 2>&1 || true

kubectl create secret generic zone-config -n policy-zone --from-literal=config=blocked >/dev/null

cat <<'EOF' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: zone-data
  namespace: policy-zone
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF

cat >"${HELPER_DIR}/secret-volume-pod.yaml" <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: secret-volume-test
  namespace: policy-zone
spec:
  serviceAccountName: psp-sa
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c", "sleep 3600"]
    volumeMounts:
    - name: config
      mountPath: /etc/config
  volumes:
  - name: config
    secret:
      secretName: zone-config
EOF

cat >"${HELPER_DIR}/pvc-volume-pod.yaml" <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: pvc-volume-test
  namespace: policy-zone
spec:
  serviceAccountName: psp-sa
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c", "sleep 3600"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: zone-data
EOF
