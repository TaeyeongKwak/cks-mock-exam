Use Trivy to scan the container images used by Pods in namespace `atlas` for `HIGH` and `CRITICAL` vulnerabilities.

Complete the following task:

1. Identify every image currently used by Pods in namespace `atlas`.
2. Scan those images with Trivy, considering only `HIGH` and `CRITICAL` findings.
3. Save the final plain-text scan output to `/opt/atlas-trivy-report.txt`.
4. Delete every Pod in namespace `atlas` that uses an image with at least one `HIGH` or `CRITICAL` vulnerability.

Notes

- A helper manifest is staged at `/root/atlas-pods.yaml`.
- You can inspect the current Pod-to-image mapping directly from the cluster or use `/opt/atlas-pod-images.txt`.
- Do not recreate Pods after deleting them.
