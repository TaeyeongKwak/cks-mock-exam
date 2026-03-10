Prepare the staged AppArmor setup for the web workload.

Tasks

1. Load the AppArmor profile from `node01:/root/web-guard.apparmor`.
2. Edit `/root/web-guard-pod.yaml` so the Pod uses that profile.
3. Run the Pod on `node01`.
4. Ensure the Pod reaches Running state with the profile applied.

Constraints

- Keep the Pod name `web-guard`.
- Use the staged profile name as-is.
- No extra Kubernetes resources are required for completion.
