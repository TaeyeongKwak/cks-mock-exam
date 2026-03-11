Namespace `qa-lab` already contains a Pod named `frontend-ui`.

Complete the following task:

1. Create a ServiceAccount named `backend-team` in namespace `qa-lab`.
2. Update the existing `frontend-ui` Pod so it uses ServiceAccount `backend-team`.
3. Ensure ServiceAccount `backend-team` cannot access any Secrets in namespace `qa-lab`.

Notes

- In Kubernetes, `serviceAccountName` is immutable on an existing Pod. Recreate the Pod with the same name if needed.
- A helper manifest is staged at `/root/frontend-ui-pod.yaml`.
- Do not grant the ServiceAccount any RBAC permissions on Secrets.

<details>
<summary>Reference Answer Commands</summary>

```bash
kubectl create serviceaccount backend-team -n qa-lab --dry-run=client -o yaml | kubectl apply -f -
vi /root/frontend-ui-pod.yaml
# set serviceAccountName: backend-team
kubectl delete pod frontend-ui -n qa-lab --ignore-not-found
kubectl apply -f /root/frontend-ui-pod.yaml
kubectl wait --for=condition=Ready pod/frontend-ui -n qa-lab --timeout=180s
kubectl auth can-i get secrets -n qa-lab --as=system:serviceaccount:qa-lab:backend-team
kubectl auth can-i list secrets -n qa-lab --as=system:serviceaccount:qa-lab:backend-team
kubectl auth can-i watch secrets -n qa-lab --as=system:serviceaccount:qa-lab:backend-team
```

</details>

