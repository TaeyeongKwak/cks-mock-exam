RBAC resources are prepared in namespace `data-core`.

Complete the following tasks:

1. Modify the existing `Role` that is bound to ServiceAccount `app-sa` and used by Pod `frontend-agent` so it allows only `get` on `pods`.
2. Create a `Role` named `app-role-b` in namespace `data-core` that allows only `update` on `statefulsets`.
3. Create a `RoleBinding` named `app-role-b-bind` that binds `app-role-b` to ServiceAccount `app-sa`.

Notes

- The ServiceAccount and Pod already exist.
- Keep the names exactly as requested.

<details>
<summary>Reference Answer Commands</summary>

```bash
kubectl edit role app-role-a -n data-core
# keep exactly one rule:
# apiGroups: [""]
# resources: ["pods"]
# verbs: ["get"]
kubectl create role app-role-b -n data-core --verb=update --resource=statefulsets.apps --dry-run=client -o yaml | kubectl apply -f -
kubectl create rolebinding app-role-b-bind -n data-core --role=app-role-b --serviceaccount=data-core:app-sa --dry-run=client -o yaml | kubectl apply -f -
kubectl auth can-i get pods -n data-core --as=system:serviceaccount:data-core:app-sa
kubectl auth can-i update statefulsets.apps -n data-core --as=system:serviceaccount:data-core:app-sa
```

</details>

