Create a NetworkPolicy named `outbound-lock` in namespace `sandbox`.

Requirements

- The policy must apply to every Pod in `sandbox`.
- It must impose default-deny behavior for egress traffic.
- If you keep DNS working, DNS must be the only remaining egress allowance.

Constraints

- Use a single NetworkPolicy resource.
- Do not add ingress rules for this task.
- If you allow DNS, restrict it to port `53` only.
