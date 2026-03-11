Create a complete deny-all NetworkPolicy for namespace `vault`.

You can start from the scaffold at `/root/policy-lab/blanket-policy.yaml`.

Requirements

- Use the existing resource name `blanket-policy`.
- The policy must apply to all Pods in `vault`.
- It must deny all ingress traffic.
- It must deny all egress traffic.

Constraints

- Keep the namespace as `vault`.
- Do not create extra NetworkPolicies.

<details>
<summary>Reference Answer Commands</summary>

```bash
cat <<'EOF' >/root/policy-lab/blanket-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: blanket-policy
  namespace: vault
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress: []
  egress: []
EOF
kubectl apply -f /root/policy-lab/blanket-policy.yaml
kubectl get networkpolicy blanket-policy -n vault -o yaml
```

</details>

