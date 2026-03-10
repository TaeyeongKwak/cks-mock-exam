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
