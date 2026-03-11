This scenario prepares RBAC resources in namespace `data-core`.

Success criteria

- The existing Role bound to `app-sa` allows only `get` on `pods`.
- A new Role `app-role-b` in namespace `data-core` allows only `update` on `statefulsets`.
- RoleBinding `app-role-b-bind` binds `app-role-b` to ServiceAccount `app-sa`.
