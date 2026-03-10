The workload still supports the intended CI job, but access to `/var/run/docker.sock` is now restricted to the authorized container user (`builder`).

This preserves the original security objective without relying on a real Docker daemon.
