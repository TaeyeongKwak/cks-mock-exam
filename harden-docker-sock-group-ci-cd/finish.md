The workload in `ci-ops` still mounts `/var/run/docker.sock`, but the Pod no longer has docker group access to it.

This preserves the exam intent: remove dangerous socket access without changing the workload type.
