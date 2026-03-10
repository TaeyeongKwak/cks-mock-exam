#!/bin/bash
set -euo pipefail

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

cat <<'EOF' | kubectl apply -f - >/dev/null
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: ciliumnetworkpolicies.cilium.io
spec:
  group: cilium.io
  names:
    kind: CiliumNetworkPolicy
    listKind: CiliumNetworkPolicyList
    plural: ciliumnetworkpolicies
    singular: ciliumnetworkpolicy
    shortNames:
    - cnp
  scope: Namespaced
  versions:
  - name: v2
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        x-kubernetes-preserve-unknown-fields: true
EOF

cat <<'EOF' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Namespace
metadata:
  name: mesh-zone
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-api
  namespace: mesh-zone
spec:
  replicas: 1
  selector:
    matchLabels:
      tier: api
      app: order-api
  template:
    metadata:
      labels:
        tier: api
        app: order-api
    spec:
      containers:
      - name: api
        image: registry.k8s.io/e2e-test-images/agnhost:2.45
        args: ["netexec", "--http-port=9000"]
---
apiVersion: v1
kind: Service
metadata:
  name: order-api
  namespace: mesh-zone
spec:
  selector:
    tier: api
    app: order-api
  ports:
  - port: 9000
    targetPort: 9000
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-db
  namespace: mesh-zone
spec:
  replicas: 1
  selector:
    matchLabels:
      tier: db
      app: order-db
  template:
    metadata:
      labels:
        tier: db
        app: order-db
    spec:
      containers:
      - name: db
        image: busybox:1.36
        command: ["sh", "-c", "sleep 3600"]
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo-store
  namespace: mesh-zone
spec:
  replicas: 1
  selector:
    matchLabels:
      service: echo-store
      app: echo-store
  template:
    metadata:
      labels:
        service: echo-store
        app: echo-store
    spec:
      containers:
      - name: echo
        image: registry.k8s.io/e2e-test-images/agnhost:2.45
        args: ["netexec", "--http-port=7070"]
---
apiVersion: v1
kind: Service
metadata:
  name: echo-store
  namespace: mesh-zone
spec:
  selector:
    service: echo-store
    app: echo-store
  ports:
  - port: 7070
    targetPort: 7070
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: diagnostics
  namespace: mesh-zone
spec:
  replicas: 1
  selector:
    matchLabels:
      app: diagnostics
  template:
    metadata:
      labels:
        app: diagnostics
    spec:
      containers:
      - name: diag
        image: busybox:1.36
        command: ["sh", "-c", "sleep 3600"]
---
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: mesh-open
  namespace: mesh-zone
spec:
  endpointSelector: {}
  ingress:
  - fromEndpoints:
    - {}
  egress:
  - toEndpoints:
    - {}
  - toEndpoints:
    - matchLabels:
        io.kubernetes.pod.namespace: kube-system
        k8s-app: kube-dns
    toPorts:
    - ports:
      - port: "53"
        protocol: UDP
      - port: "53"
        protocol: TCP
EOF

kubectl delete cnp db-authz -n mesh-zone --ignore-not-found >/dev/null 2>&1 || true
kubectl delete cnp no-icmp-probe -n mesh-zone --ignore-not-found >/dev/null 2>&1 || true

kubectl wait -n mesh-zone --for=condition=Available deployment/order-api deployment/order-db deployment/echo-store deployment/diagnostics --timeout=180s >/dev/null
