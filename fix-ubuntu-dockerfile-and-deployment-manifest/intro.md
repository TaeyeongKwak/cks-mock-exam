This scenario rewrites a Dockerfile and Kubernetes manifest review task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- The files to edit are staged under `/home/review-manifests`.
- A helper script is staged at `/home/review-manifests/entrypoint.sh`.

Success criteria

- The Dockerfile still uses `ubuntu:20.04` and is updated to use unprivileged user `nobody` with UID `65535`.
- The Deployment manifest remains structurally unchanged but no longer runs as root.
- The Deployment manifest enables `runAsNonRoot` for the container.
