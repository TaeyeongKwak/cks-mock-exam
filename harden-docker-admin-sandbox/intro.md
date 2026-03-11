This scenario rewrites a workload-hardening task for the default Killercoda Kubernetes playground.

Environment notes

- The terminal starts on `controlplane`.
- Namespace `sandbox-lab` already contains Deployment `docker-ops`.
- A helper manifest is staged at `/root/sandbox/docker-ops.yaml`.

Success criteria

- `docker-ops` still exists in namespace `sandbox-lab` and still mounts `/var/run/docker.sock`.
- The Pod template no longer runs as root.
- The container drops all Linux capabilities and uses a read-only root filesystem.
