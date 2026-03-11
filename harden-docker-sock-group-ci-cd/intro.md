This scenario rewrites a workload hardening task for the default Killercoda Kubernetes playground.

Environment notes

- The terminal starts on `controlplane`.
- Namespace `ci-ops` contains one Deployment with a Pod that mounts `/var/run/docker.sock`.
- A helper manifest is staged at `/root/ci-ops-deployment.yaml`.

Success criteria

- The workload in namespace `ci-ops` still mounts `/var/run/docker.sock`.
- The running Pod in `ci-ops` can no longer read or write the mounted socket.
- The Deployment remains healthy after the update.
