This scenario rewrites a Kubernetes ServiceAccount hardening task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- Namespace `qa-lab` already contains a Pod named `frontend-ui`.
- A helper manifest is staged at `/root/frontend-ui-pod.yaml`.

Success criteria

- A ServiceAccount named `backend-team` exists in namespace `qa-lab`.
- Pod `frontend-ui` in `qa-lab` uses ServiceAccount `backend-team`.
- ServiceAccount `backend-team` cannot get, list, or watch Secrets in namespace `qa-lab`.
