This scenario rewrites a Kubernetes RBAC task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- Namespace `qa-system` already contains Pod `web-pod`.
- Directory `/candidate` is available for the required output file.

Adaptation notes

- The source task does not require a specific Role or RoleBinding name, so this scenario accepts any valid names.
- The staged Pod uses a non-default ServiceAccount so the learner must fetch the actual value from the Pod spec.
- Verification checks the saved file, the bound Role rule, and the resulting permissions of the Pod's ServiceAccount.

Success criteria

- `/candidate/current-sa.txt` contains the exact ServiceAccount name used by `web-pod`.
- In namespace `qa-system`, that ServiceAccount is bound to a Role that grants only `get`, `list`, and `watch` on `deployments`.
- The ServiceAccount can `get`, `list`, and `watch` Deployments in `qa-system`.
