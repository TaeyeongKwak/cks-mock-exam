Use KubeSec to harden the staged Pod manifest.

Complete the following task:

1. Scan `/root/kubesec-test.yaml` with the staged KubeSec-style scanner.
2. Apply the recommended security changes to the same file.
3. Ensure the manifest reaches a score of at least `4`.

Requirements

- Keep the Pod name `kubesec-demo`.
- Ensure the container runs as non-root with UID `1000`.
- Disable privilege escalation.
- Drop all Linux capabilities.
- Keep the root filesystem read-only.

Notes

- Use `kubesec scan /root/kubesec-test.yaml` to inspect the current score.
- The manifest only needs to validate and score correctly; you do not need to create the Pod.

<details>
<summary>Show answer</summary>

```bash
kubesec scan /root/kubesec-test.yaml

cat <<'EOF' >/root/kubesec-test.yaml
apiVersion: v1
kind: Pod
metadata:
  name: kubesec-demo
spec:
  containers:
  - name: kubesec-demo
    image: gcr.io/google-samples/node-hello:1.0
    securityContext:
      runAsUser: 1000
      runAsNonRoot: true
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
EOF

kubesec scan /root/kubesec-test.yaml
kubectl apply --dry-run=client -f /root/kubesec-test.yaml
```

</details>
