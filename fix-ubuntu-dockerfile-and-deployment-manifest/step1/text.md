Review the staged Dockerfile and Kubernetes Deployment manifest under `/home/review-manifests`.

Files

- `/home/review-manifests/Dockerfile`
- `/home/review-manifests/deployment.yaml`

Requirements

- Fix two prominent security or best-practice issues in the Dockerfile.
- Fix two prominent security or best-practice issues in the Deployment manifest.
- Do not add or remove other configuration. Only edit the existing configuration.
- Where a non-root user is needed, use unprivileged user `nobody` with UID `65535`.

Notes

- Keep the existing Deployment name `security-review-demo`.
- You do not need to build the image or apply the Deployment.
