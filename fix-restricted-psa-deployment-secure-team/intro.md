This scenario rewrites a Pod Security Admission task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- Namespace `secure-lab` already exists.
- `secure-lab` enforces the Pod Security Admission `restricted` profile.
- The Deployment manifest to fix is staged at `/root/masters/restricted-fix.yaml`.

Adaptation notes

- The source file path `/home/masters/insecure-deployment.yaml` is normalized to `/root/masters/restricted-fix.yaml`.
- The staged Deployment contains several common `restricted` profile violations so the exercise remains deterministic on the default playground.

Success criteria

- The edited Deployment manifest is accepted in namespace `secure-lab`.
- The Deployment rolls out successfully.
- The resulting Pod template satisfies the `restricted` Pod Security profile checks used in this scenario.
