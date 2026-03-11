This scenario rewrites a privileged-Pod prevention task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- Namespace `policy-lab` already exists.
- Helper Pod manifests are staged under `/root/policy-lab`.

Success criteria

- ServiceAccount `psp-sa`, ClusterRole `prevent-role`, and ClusterRoleBinding `prevent-role-binding` exist.
- `prevent-role` allows creating Pods.
- The admission policy blocks privileged Pod creation only in namespace `policy-lab`.
- The staged privileged Pod manifest is rejected when created as `psp-sa`, while the staged non-privileged Pod manifest is accepted with server dry-run.
