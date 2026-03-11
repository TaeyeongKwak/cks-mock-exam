Namespace `mesh-zone` already contains a permissive baseline Cilium policy named `mesh-open`.

Create two additional namespaced `CiliumNetworkPolicy` resources with these names:

1. `db-authz`
2. `no-icmp-probe`

Required behavior

- `db-authz` must require authenticated egress from Pods labeled `tier=db` to Pods labeled `tier=api`.
- `no-icmp-probe` must deny ICMP egress from Pods labeled `app=diagnostics` to the workload behind Service `echo-store`.

Constraints

- Keep the existing `mesh-open` policy.
- Do not replace the staged Deployments or Services.
- Use namespaced Cilium policies in `mesh-zone`.

<details>
<summary>Reference Answer Commands</summary>

```bash
cat <<'EOF' >/tmp/db-authz.yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: db-authz
  namespace: mesh-zone
spec:
  endpointSelector:
    matchLabels:
      tier: db
  egress:
  - toEndpoints:
    - matchLabels:
        tier: api
    authentication:
      mode: required
EOF
cat <<'EOF' >/tmp/no-icmp-probe.yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: no-icmp-probe
  namespace: mesh-zone
spec:
  endpointSelector:
    matchLabels:
      app: diagnostics
  egressDeny:
  - toServices:
    - k8sService:
        serviceName: echo-store
        namespace: mesh-zone
    icmps:
    - fields:
      - type: 8
        family: IPv4
EOF
kubectl apply -f /tmp/db-authz.yaml
kubectl apply -f /tmp/no-icmp-probe.yaml
kubectl get cnp -n mesh-zone
```

</details>

