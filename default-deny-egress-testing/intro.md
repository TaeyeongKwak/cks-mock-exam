This lab focuses on egress isolation with a single namespace-wide NetworkPolicy.

Prepared environment

- You start on `controlplane`.
- Namespace `sandbox` already exists.
- No helper manifests are required.

Scenario notes

- The target behavior is deny-by-default for outbound traffic.
- DNS can remain open if you choose to preserve name resolution.

Completion target

- One NetworkPolicy in `sandbox` selects every Pod.
- Egress is blocked by default.
- If any egress is still allowed, it is limited strictly to DNS on port `53`.
