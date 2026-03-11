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

<details>
<summary>Reference Answer Commands</summary>

```bash
vi /root/Dockerfile
# Replace ubuntu:latest with a pinned ubuntu tag.
# Create test-user with UID 5375.
# Make the USER instruction run as test-user or 5375 instead of root.
vi /root/pod-security-audit.yaml
# Change securityContext.runAsUser to 5375.
# Change securityContext.privileged to false.
# Keep allowPrivilegeEscalation as false.
kubectl apply --dry-run=client -f /root/pod-security-audit.yaml
grep -E '^(FROM|USER|RUN .*useradd|RUN .*adduser)' /root/Dockerfile
```

</details>

