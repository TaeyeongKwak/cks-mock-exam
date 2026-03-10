This scenario rewrites a Kubernetes security hardening task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- The files to edit are staged at `/root/Dockerfile` and `/root/pod-security-audit.yaml`.
- A helper script is staged at `/root/entrypoint.sh`.

Success criteria

- Fix two security issues in the Dockerfile.
- Fix two security issues in the Pod manifest.
- Do not add or remove YAML fields. Only edit existing values.
- When a non-root user is needed, use `test-user` with UID `5375`.
