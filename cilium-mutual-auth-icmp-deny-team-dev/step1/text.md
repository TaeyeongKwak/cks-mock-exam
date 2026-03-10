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
