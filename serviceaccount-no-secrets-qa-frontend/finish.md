Pod `frontend-ui` now runs with ServiceAccount `backend-team`, and that ServiceAccount has no access to Secrets in namespace `qa-lab`.

This keeps the workload identity minimal while preserving the original task intent.
