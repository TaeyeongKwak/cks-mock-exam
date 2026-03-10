This scenario rewrites a Kubernetes ServiceAccount hardening task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- Namespace `qa-lab` already contains a Pod named `frontend-ui`.
- A helper manifest is staged at `/root/frontend-ui-pod.yaml`.

Adaptation notes

- In Kubernetes, `spec.serviceAccountName` on an existing Pod is immutable.
- To preserve the exam intent, this scenario accepts recreating the `frontend` Pod with the same name so it uses the new ServiceAccount.
- The goal is to ensure ServiceAccount `backend-team` has no permission to access Secrets.

Success criteria

- A ServiceAccount named `backend-team` exists in namespace `qa-lab`.
- Pod `frontend-ui` in `qa-lab` uses ServiceAccount `backend-team`.
- ServiceAccount `backend-team` cannot get, list, or watch Secrets in namespace `qa-lab`.
