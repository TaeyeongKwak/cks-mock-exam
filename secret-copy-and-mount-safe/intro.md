This scenario rewrites a Kubernetes Secret handling task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- Namespace `vault` already exists.
- The existing Secret `root-admin` is already present in namespace `vault`.

Success criteria

- The fields from Secret `root-admin` are written to:
  - `/root/secret-lab/username.txt`
  - `/root/secret-lab/password.txt`
- Secret `app-secret` exists in namespace `vault` with:
  - `username=dbadmin`
  - `password=moresecurepas`
- Pod `secret-mount-pod` in namespace `vault` mounts Secret `app-secret`.
