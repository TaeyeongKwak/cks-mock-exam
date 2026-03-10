This lab focuses on issuing a Kubernetes client certificate and binding namespace-scoped permissions.

Prepared environment

- You start on `controlplane`.
- Namespace `tenant-user` already exists.
- The kubeadm control plane CA is available through the normal node filesystem.
- A workspace for artifacts is staged at `/srv/cert-lab`.

Target outcome

- A client identity named `marie` has a key, CSR, approved Kubernetes CSR object, and signed certificate.
- Namespace `tenant-user` contains a Role and RoleBinding tied to that user.
- The resulting user can `list`, `get`, `create`, and `delete` Pods and Secrets in `tenant-user`.
