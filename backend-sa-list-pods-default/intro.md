This lab focuses on building a minimal namespaced identity for Pod inventory access.

Prepared environment

- You start on `controlplane`.
- All work happens in namespace `default`.
- No manifests are pre-staged; create the required resources directly.

Target outcome

- A ServiceAccount exists for a read-only inventory task.
- That identity can list Pods in `default` and nothing broader is required for this lab.
- A running Pod uses the same ServiceAccount so the configuration is exercised in-cluster.
