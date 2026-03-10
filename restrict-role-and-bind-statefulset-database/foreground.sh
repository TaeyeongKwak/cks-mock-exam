#!/bin/bash
set -euo pipefail

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

cat <<'EOF' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Namespace
metadata:
  name: data-core
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  namespace: data-core
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-role-a
  namespace: data-core
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-role-a-bind
  namespace: data-core
subjects:
- kind: ServiceAccount
  name: app-sa
  namespace: data-core
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: app-role-a
---
apiVersion: v1
kind: Pod
metadata:
  name: frontend-agent
  namespace: data-core
spec:
  serviceAccountName: app-sa
  nodeName: controlplane
  containers:
  - name: web
    image: registry.k8s.io/pause:3.9
EOF

kubectl delete rolebinding app-role-b-bind -n data-core --ignore-not-found >/dev/null 2>&1 || true
kubectl delete role app-role-b -n data-core --ignore-not-found >/dev/null 2>&1 || true
kubectl wait -n data-core --for=condition=Ready pod/frontend-agent --timeout=180s >/dev/null
