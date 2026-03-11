Create a lightweight namespace-scoped identity for Pod inventory work in `default`.

Tasks

1. Create a ServiceAccount named `viewer-sa`.
2. Create a Role named `pod-viewer` in `default` that grants only `list` on `pods`.
3. Create a RoleBinding named `pod-viewer-bind` that attaches that Role to `viewer-sa`.
4. Launch a Pod named `inventory-shell` in `default` that uses `viewer-sa`.

Constraints

- Keep all resources in namespace `default`.
- The Pod only needs to stay running.
- Do not grant extra Pod verbs beyond what is required.

<details>
<summary>Reference Answer Commands</summary>

```bash
kubectl get all -n default
kubectl create serviceaccount viewer-sa -n default --dry-run=client -o yaml | kubectl apply -f -
kubectl create role pod-viewer -n default --verb=list --resource=pods --dry-run=client -o yaml | kubectl apply -f -
kubectl create rolebinding pod-viewer-bind -n default --role=pod-viewer --serviceaccount=default:viewer-sa --dry-run=client -o yaml | kubectl apply -f -
kubectl run inventory-shell -n default --image=busybox:1.36 --serviceaccount=viewer-sa --restart=Never -- sh -c 'sleep 3600'
kubectl wait --for=condition=Ready pod/inventory-shell -n default --timeout=180s
kubectl auth can-i list pods -n default --as=system:serviceaccount:default:viewer-sa
```

</details>

