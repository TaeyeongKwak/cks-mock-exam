This scenario rewrites a workload hardening task for the default Killercoda Kubernetes playground.

Environment notes

- The terminal starts on `controlplane`.
- Namespace `ci-ops` contains one Deployment with a Pod that mounts `/var/run/docker.sock`.
- A helper manifest is staged at `/root/ci-ops-deployment.yaml`.

Adaptation notes

- The default playground uses containerd, not Docker. To preserve the original security objective, this scenario stages a host file at `/var/run/docker.sock`.
- The staged socket file uses group ID `123` to represent the host `docker` group and has permissions `0660`.
- The vulnerable Pod is configured with supplemental group `123`, which allows the container process to access the mounted socket.

Success criteria

- The workload in namespace `ci-ops` still mounts `/var/run/docker.sock`.
- The running Pod in `ci-ops` can no longer read or write the mounted socket.
- The Deployment remains healthy after the update.
