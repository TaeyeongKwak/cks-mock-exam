This scenario rewrites a Trivy-based image hygiene task for the default Killercoda Kubernetes playground.

Environment notes

- The terminal starts on `controlplane`.
- Trivy is installed during scenario setup.
- Namespace `atlas` already contains several Pods.
- A helper manifest is staged at `/root/atlas-pods.yaml`.
- Save your scan results as plain text to `/opt/atlas-trivy-report.txt`.

Success criteria

- All images used by Pods in namespace `atlas` are scanned with Trivy.
- The saved report only contains `HIGH` and `CRITICAL` results.
- Every Pod in `atlas` that uses a severely vulnerable image is deleted.
- Pods whose images are not severely vulnerable remain.
