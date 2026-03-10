Namespace `qa-lab` already contains a Pod named `frontend-ui`.

Complete the following task:

1. Create a ServiceAccount named `backend-team` in namespace `qa-lab`.
2. Update the existing `frontend-ui` Pod so it uses ServiceAccount `backend-team`.
3. Ensure ServiceAccount `backend-team` cannot access any Secrets in namespace `qa-lab`.

Notes

- In Kubernetes, `serviceAccountName` is immutable on an existing Pod. Recreate the Pod with the same name if needed.
- A helper manifest is staged at `/root/frontend-ui-pod.yaml`.
- Do not grant the ServiceAccount any RBAC permissions on Secrets.
