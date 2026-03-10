#!/bin/bash
set -euo pipefail

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: access-lab
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sa-app-1
  namespace: access-lab
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: role-a
  namespace: access-lab
rules:
- apiGroups: [""]
  resources: ["pods","services"]
  verbs: ["get","list","watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: role-a-bind
  namespace: access-lab
subjects:
- kind: ServiceAccount
  name: sa-app-1
  namespace: access-lab
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: role-a
---
apiVersion: v1
kind: Pod
metadata:
  name: frontend-pod
  namespace: access-lab
spec:
  serviceAccountName: sa-app-1
  containers:
  - name: web
    image: registry.k8s.io/pause:3.9
EOF

kubectl delete clusterrolebinding role-b-bind --ignore-not-found >/dev/null
kubectl delete clusterrole role-b --ignore-not-found >/dev/null
kubectl wait -n access-lab --for=condition=Ready pod/frontend-pod --timeout=180s >/dev/null
