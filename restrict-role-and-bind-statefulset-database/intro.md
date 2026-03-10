This scenario prepares RBAC resources in namespace `data-core`.

Adaptation notes

- The playground uses the default two-node kubeadm cluster.
- The ServiceAccount `app-sa` and Pod `frontend-agent` are pre-created in namespace `data-core`.
- An existing namespaced Role is already bound to `app-sa`, but it is over-permissive and must be corrected.

Success criteria

- The existing Role bound to `app-sa` allows only `get` on `pods`.
- A new Role `app-role-b` in namespace `data-core` allows only `update` on `statefulsets`.
- RoleBinding `app-role-b-bind` binds `app-role-b` to ServiceAccount `app-sa`.
