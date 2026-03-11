Create a NetworkPolicy named `outbound-lock` in namespace `sandbox`.

Requirements

- The policy must apply to every Pod in `sandbox`.
- It must impose default-deny behavior for egress traffic.
- If you keep DNS working, DNS must be the only remaining egress allowance.

Constraints

- Use a single NetworkPolicy resource.
- Do not add ingress rules for this task.
- If you allow DNS, restrict it to port `53` only.

<details>
<summary>Reference Answer Commands</summary>

```bash
cat <<'EOF' >/tmp/outbound-lock.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: outbound-lock
  namespace: sandbox
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress: []
EOF
kubectl apply -f /tmp/outbound-lock.yaml
# Optional DNS-only variant:
# egress:
# - ports:
#   - protocol: UDP
#     port: 53
#   - protocol: TCP
#     port: 53
kubectl get networkpolicy outbound-lock -n sandbox -o yaml
```

</details>

