This scenario rewrites a privileged-Pod prevention task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- Namespace `policy-lab` already exists.
- Helper Pod manifests are staged under `/root/policy-lab`.

Adaptation notes

- PodSecurityPolicy is removed in modern Kubernetes and is not available on the default Killercoda backend.
- This scenario replaces the PSP with a `ValidatingAdmissionPolicy` named `prevent-privileged-policy` and a binding named `prevent-privileged-binding` scoped to namespace `policy-lab`.
- The ServiceAccount, ClusterRole, and ClusterRoleBinding are still part of the exercise so you can verify that Pod creation is allowed by RBAC but blocked by admission policy.

Success criteria

- ServiceAccount `psp-sa`, ClusterRole `prevent-role`, and ClusterRoleBinding `prevent-role-binding` exist.
- `prevent-role` allows creating Pods.
- The admission policy blocks privileged Pod creation only in namespace `policy-lab`.
- The staged privileged Pod manifest is rejected when created as `psp-sa`, while the staged non-privileged Pod manifest is accepted with server dry-run.
