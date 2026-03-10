Create a new Kubernetes client identity and namespace-scoped access rule set.

Tasks

1. Generate a private key and CSR for user `marie`.
2. Create a Kubernetes CSR object named `marie-access` and approve it.
3. Retrieve the signed certificate and save it locally.
4. Create a Role named `tenant-editor` in namespace `tenant-user` that allows `list`, `get`, `create`, and `delete` on `pods` and `secrets`.
5. Create a RoleBinding named `tenant-editor-bind` that binds that Role to user `marie`.
6. Verify the granted access.

Notes

- A suggested workspace is available at `/srv/cert-lab`.
- Keep the namespace `tenant-user`.
- Keep the Role and RoleBinding names exactly as requested.
