This scenario rewrites a socket-permission hardening task for the default Killercoda Kubernetes playground.

Environment notes

- The terminal starts on `controlplane`.
- Namespace `ci-sec` contains a Deployment named `build-runner`.
- The Deployment has two containers: `builder` is the intended CI job container, and `observer` is not authorized to control the Docker daemon.
- A helper manifest is staged at `/root/build-runner.yaml`.

Adaptation notes

- The default playground uses containerd, not Docker. To preserve the original exercise intent, this scenario stages a host file at `/var/run/docker.sock`.
- The staged file starts as `root:docker` with permissions equivalent to `0660`. In this scenario, group ID `123` represents the host `docker` group.
- "Can run arbitrary containers" is modeled as read and write access to `/var/run/docker.sock`. If a container cannot open that file, it is treated as unauthorized to control the daemon.

Success criteria

- The `builder` container can still access `/var/run/docker.sock`.
- The `observer` container can no longer read or write `/var/run/docker.sock`.
- The mounted file inside the Pod is owned by UID `1000`, GID `1000`, and has mode `0600`.
