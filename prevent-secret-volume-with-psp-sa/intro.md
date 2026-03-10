This scenario rewrites a PodSecurityPolicy-based volume restriction task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- Namespace `policy-zone` already exists.
- Helper Pod manifests are staged under `/root/policy-zone`.

Adaptation notes

- PodSecurityPolicy was removed in Kubernetes v1.25 and is not available on the default Killercoda backend.
- This scenario replaces the PSP with a `ValidatingAdmissionPolicy` named `prevent-volume-policy` and a binding named `prevent-volume-policy-binding` scoped to namespace `policy-zone`.
- The ServiceAccount, ClusterRole, and ClusterRoleBinding remain part of the exercise so RBAC and admission behavior can both be verified.

Success criteria

- ServiceAccount `psp-sa`, ClusterRole `psp-role`, and ClusterRoleBinding `psp-role-binding` exist.
- The admission policy allows only `persistentVolumeClaim` volumes for Pods in namespace `policy-zone`.
- A staged Pod manifest with a Secret volume is rejected when created as `psp-sa`.
- A staged Pod manifest with a PVC volume is accepted with server dry-run.
