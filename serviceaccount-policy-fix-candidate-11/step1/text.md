The Pod manifest at `/home/candidate/11/ui-pod.yaml` currently uses an incorrect ServiceAccount and does not comply with the organization policy.

Complete the following task:

1. Create a ServiceAccount named `ui-sa` in namespace `qa-lab`.
2. Ensure that ServiceAccount does not automount API credentials.
3. Update `/home/candidate/11/ui-pod.yaml` so the Pod uses `ui-sa`.
4. Apply the Pod manifest successfully.
5. Clean up the unused ServiceAccounts in namespace `qa-lab`.

Notes

- ServiceAccount names must end with `-sa`.
- Keep the Pod name as `frontend-ui`.
- The built-in `default` ServiceAccount may remain.
