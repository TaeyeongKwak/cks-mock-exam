This lab focuses on finishing a full deny-all NetworkPolicy manifest.

Prepared environment

- You start on `controlplane`.
- Namespace `vault` already exists.
- A manifest scaffold is staged at `/root/policy-lab/blanket-policy.yaml`.

Scenario notes

- The staged file already contains the target resource name.
- Your task is to complete it so every Pod in `vault` is isolated for both ingress and egress.

Completion target

- NetworkPolicy `blanket-policy` exists in namespace `vault`.
- The policy selects every Pod in `vault`.
- It blocks all ingress and all egress traffic.
