You are given a Dockerfile and a Pod manifest with security best practice violations.

Files

- `/root/Dockerfile`
- `/root/pod-security-audit.yaml`

Requirements

- Fix two issues in the Dockerfile.
- Fix two issues in the Pod manifest.
- Do not add or remove fields. Only edit existing ones.
- When a non-root user is needed, use `test-user` with UID `5375`.

Notes

- Keep the existing resource name `security-audit-pod`.
- The manifest only needs to be valid after your edits. You do not need to create the Pod.
