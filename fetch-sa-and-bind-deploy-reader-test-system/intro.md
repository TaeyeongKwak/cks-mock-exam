This scenario rewrites a Kubernetes RBAC task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- Namespace `qa-system` already contains Pod `web-pod`.
- Directory `/candidate` is available for the required output file.

Success criteria

- `/candidate/current-sa.txt` contains the exact ServiceAccount name used by `web-pod`.
- In namespace `qa-system`, that ServiceAccount is bound to a Role that grants only `get`, `list`, and `watch` on `deployments`.
- The ServiceAccount can `get`, `list`, and `watch` Deployments in `qa-system`.
