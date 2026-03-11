RBAC resources are prepared in namespace `access-lab`.

Complete the following tasks:

1. Modify the existing `Role` that is bound to ServiceAccount `sa-app-1` and used by Pod `frontend-pod` so it allows only `watch` on `services`.
2. Create a `ClusterRole` named `role-b` that allows only `update` on `namespaces`.
3. Create a `ClusterRoleBinding` named `role-b-bind` that binds `role-b` to ServiceAccount `sa-app-1`.

Notes

- The ServiceAccount and Pod already exist.
- Keep the names exactly as requested.

<details>
<summary>Reference Answer Commands</summary>

```bash
kubectl edit role role-a -n access-lab
# keep exactly one rule:
# apiGroups: [""]
# resources: ["services"]
# verbs: ["watch"]
kubectl create clusterrole role-b --verb=update --resource=namespaces --dry-run=client -o yaml | kubectl apply -f -
kubectl create clusterrolebinding role-b-bind --clusterrole=role-b --serviceaccount=access-lab:sa-app-1 --dry-run=client -o yaml | kubectl apply -f -
kubectl auth can-i watch services -n access-lab --as=system:serviceaccount:access-lab:sa-app-1
kubectl auth can-i update namespaces --as=system:serviceaccount:access-lab:sa-app-1
```

</details>

