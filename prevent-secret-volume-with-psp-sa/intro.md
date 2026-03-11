This scenario rewrites a PodSecurityPolicy-based volume restriction task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- Namespace `policy-zone` already exists.
- Helper Pod manifests are staged under `/root/policy-zone`.

Success criteria

- ServiceAccount `psp-sa`, ClusterRole `psp-role`, and ClusterRoleBinding `psp-role-binding` exist.
- The admission policy allows only `persistentVolumeClaim` volumes for Pods in namespace `policy-zone`.
- A staged Pod manifest with a Secret volume is rejected when created as `psp-sa`.
- A staged Pod manifest with a PVC volume is accepted with server dry-run.
