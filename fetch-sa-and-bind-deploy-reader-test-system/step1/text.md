There is an existing Pod named `web-pod` in namespace `qa-system`.

Complete the following tasks:

1. Fetch the Pod's ServiceAccount name and save it to `/candidate/current-sa.txt`.
2. Create a Role in namespace `qa-system` that can `get`, `list`, and `watch` `deployments`.
3. Bind that Role to the ServiceAccount used by `web-pod`.

Notes

- The Role and RoleBinding names are up to you.
- Use namespace `qa-system`.
- The terminal starts on `controlplane`.

<details>
<summary>Reference Answer Commands</summary>

```bash
kubectl get pod web-pod -n qa-system -o jsonpath='{.spec.serviceAccountName}' | tee /candidate/current-sa.txt
SA_NAME=$(cat /candidate/current-sa.txt)
kubectl create role deploy-reader -n qa-system --verb=get,list,watch --resource=deployments.apps --dry-run=client -o yaml | kubectl apply -f -
kubectl create rolebinding deploy-reader-bind -n qa-system --role=deploy-reader --serviceaccount=qa-system:${SA_NAME} --dry-run=client -o yaml | kubectl apply -f -
kubectl auth can-i list deployments.apps -n qa-system --as=system:serviceaccount:qa-system:${SA_NAME}
```

</details>

