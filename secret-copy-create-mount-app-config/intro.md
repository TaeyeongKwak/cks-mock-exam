This scenario rewrites a Kubernetes Secret handling task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- Namespaces `dev-sec` and `portal` already exist.
- Secret `default-token-alpha` already exists in namespace `dev-sec`.
- A helper manifest for the application Pod is staged at `/root/web-config-pod.yaml`.

Adaptation notes

- Modern Kubernetes clusters do not automatically create legacy ServiceAccount token Secrets. To preserve the original task intent, this scenario stages a Secret named `default-token-alpha` with a `ca.crt` key in namespace `dev-sec`.
- The source task only says to save the data to a file named `ca.crt`. For deterministic scoring in this playground, save it to `/root/cluster-ca.crt`.

Success criteria

- The `ca.crt` data from Secret `default-token-alpha` is written to `/root/cluster-ca.crt`.
- Secret `web-config-secret` exists in namespace `portal` with:
  - `APP_USER=appadmin`
  - `APP_PASS=Sup3rS3cret`
- Pod `web-config-pod` in namespace `portal` uses image `nginx` and mounts Secret `web-config-secret` at `/etc/app-config`.
