This scenario rewrites a workload-hardening task for the default Killercoda Kubernetes playground.

Environment notes

- The terminal starts on `controlplane`.
- Namespace `sandbox-lab` already contains Deployment `docker-ops`.
- A helper manifest is staged at `/root/sandbox/docker-ops.yaml`.

Adaptation notes

- The default playground uses containerd, not Docker. To preserve the original exam intent, this scenario creates a host file at `/var/run/docker.sock` and mounts it into the Deployment with `hostPath`.
- The goal is to keep the Deployment running and reduce risk with Kubernetes security settings instead of deleting the workload or removing the mount.
- The staged Deployment is intentionally insecure so verification fails until you harden it.
- The staged container only runs `sleep 3600`, so this scenario expects no added Linux capabilities after hardening.

Success criteria

- `docker-ops` still exists in namespace `sandbox-lab` and still mounts `/var/run/docker.sock`.
- The Pod template no longer runs as root.
- The container drops all Linux capabilities and uses a read-only root filesystem.
