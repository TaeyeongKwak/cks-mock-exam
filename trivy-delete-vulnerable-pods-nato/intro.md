This scenario rewrites a Trivy-based image hygiene task for the default Killercoda Kubernetes playground.

Environment notes

- The terminal starts on `controlplane`.
- Trivy is installed during scenario setup.
- Namespace `atlas` already contains several Pods.
- A helper manifest is staged at `/root/atlas-pods.yaml`.
- Save your scan results as plain text to `/opt/atlas-trivy-report.txt`.

Adaptation notes

- Vulnerability data changes over time as the Trivy database is updated.
- To keep verification deterministic, the scenario computes the expected set of severely vulnerable images during bootstrap with the same Trivy installation that the learner will use.
- In this scenario, a Pod is considered severely vulnerable when its image has at least one `HIGH` or `CRITICAL` finding from Trivy.

Success criteria

- All images used by Pods in namespace `atlas` are scanned with Trivy.
- The saved report only contains `HIGH` and `CRITICAL` results.
- Every Pod in `atlas` that uses a severely vulnerable image is deleted.
- Pods whose images are not severely vulnerable remain.
