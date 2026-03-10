Scenario complete.

The `docker-ops` Deployment in `sandbox-lab` still mounts `/var/run/docker.sock`, but it now runs as non-root with all capabilities dropped and a read-only root filesystem.
