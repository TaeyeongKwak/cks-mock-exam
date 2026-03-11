Use KubeSec to scan the staged Pod manifest and improve its score.

Files and tools

- Manifest: `/root/kubesec-audit.yaml`
- Helper to run the official KubeSec image: `/usr/local/bin/kubesec-docker-scan`

Requirements

- Scan `/root/kubesec-audit.yaml` with KubeSec.
- Apply the recommended security fixes to the manifest.
- Reach a KubeSec score of at least `4`.

Notes

- The helper script runs the official image `docker.io/kubesec/kubesec:v2` through containerd.
- You only need to edit the staged manifest file.

<details>
<summary>Reference Answer Commands</summary>

```bash
/usr/local/bin/kubesec-docker-scan /root/kubesec-audit.yaml | jq .
vi /root/kubesec-audit.yaml
# Add or fix the common KubeSec improvements:
# automountServiceAccountToken: false
# securityContext.runAsNonRoot: true
# container securityContext.allowPrivilegeEscalation: false
# container securityContext.readOnlyRootFilesystem: true
# container securityContext.capabilities.drop: ["ALL"]
/usr/local/bin/kubesec-docker-scan /root/kubesec-audit.yaml | jq '.[0] | {score, valid}'
kubectl apply --dry-run=client -f /root/kubesec-audit.yaml
```

</details>

