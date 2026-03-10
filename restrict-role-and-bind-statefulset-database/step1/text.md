RBAC resources are prepared in namespace `data-core`.

Complete the following tasks:

1. Modify the existing `Role` that is bound to ServiceAccount `app-sa` and used by Pod `frontend-agent` so it allows only `get` on `pods`.
2. Create a `Role` named `app-role-b` in namespace `data-core` that allows only `update` on `statefulsets`.
3. Create a `RoleBinding` named `app-role-b-bind` that binds `app-role-b` to ServiceAccount `app-sa`.

Notes

- The ServiceAccount and Pod already exist.
- Keep the names exactly as requested.
