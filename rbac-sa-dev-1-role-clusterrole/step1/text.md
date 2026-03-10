RBAC resources are prepared in namespace `access-lab`.

Complete the following tasks:

1. Modify the existing `Role` that is bound to ServiceAccount `sa-app-1` and used by Pod `frontend-pod` so it allows only `watch` on `services`.
2. Create a `ClusterRole` named `role-b` that allows only `update` on `namespaces`.
3. Create a `ClusterRoleBinding` named `role-b-bind` that binds `role-b` to ServiceAccount `sa-app-1`.

Notes

- The ServiceAccount and Pod already exist.
- Keep the names exactly as requested.
