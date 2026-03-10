The `quarantine` namespace must become a dead-end segment.

Task

- Create a NetworkPolicy named `air-gap` in namespace `quarantine`.

Requirements

- It must apply to every Pod in `quarantine`.
- It must block all ingress.
- It must block all egress.

Constraints

- Do not modify Pods in `quarantine` or `edge`.
- Do not solve this with multiple policies.
