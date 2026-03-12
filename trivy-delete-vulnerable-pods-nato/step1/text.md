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
- Make sure the plain-text report includes the image name for every scanned image, even when the image has no HIGH or CRITICAL findings.

<details>
<summary>Reference Answer Commands</summary>

```bash
kubectl get pods -n atlas -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.containers[0].image}{"\n"}{end}' | sort > /opt/atlas-pod-images.txt
: > /opt/atlas-trivy-report.txt
while read -r pod image; do
  echo "=== $image ===" | tee -a /opt/atlas-trivy-report.txt
  trivy image --severity HIGH,CRITICAL "$image" | tee -a /opt/atlas-trivy-report.txt
  if trivy image --quiet --severity HIGH,CRITICAL --format json "$image" | jq -e '.Results[]? | select(.Vulnerabilities and (.Vulnerabilities|length>0))' >/dev/null; then
    kubectl delete pod "$pod" -n atlas
  fi
done < /opt/atlas-pod-images.txt
kubectl get pods -n atlas -o wide
```

</details>

