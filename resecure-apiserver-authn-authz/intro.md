This scenario rewrites a Kubernetes exam-style control plane hardening task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- The API server is intentionally misconfigured.
- The API server static Pod manifest is at `/etc/kubernetes/manifests/kube-apiserver.yaml`.
- Use `/etc/kubernetes/admin.conf` for authenticated `kubectl` access after you complete the fix.

Success criteria

- The API server uses `--authorization-mode=Node,RBAC`.
- The API server enables the `NodeRestriction` admission controller.
- The API server disables anonymous authentication.
- The `ClusterRoleBinding` `anonymous-admin-binding` granting `cluster-admin` to `system:anonymous` is removed.
- Anonymous requests are denied, while authenticated requests using `/etc/kubernetes/admin.conf` still work.
