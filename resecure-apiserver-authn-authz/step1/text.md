The cluster API server was temporarily weakened and now allows unauthenticated access.

Re-secure the cluster so that only authenticated and authorized REST requests are allowed.

Requirements

- Use authorization mode `Node,RBAC`.
- Use admission controller `NodeRestriction`.
- Disable `--anonymous-auth`.
- Remove the `ClusterRoleBinding` `anonymous-admin-binding` that grants `cluster-admin` access to `system:anonymous`.
- After the fix, use the original kubeconfig `/etc/kubernetes/admin.conf` for authenticated `kubectl` access.

Notes

- Edit `/etc/kubernetes/manifests/kube-apiserver.yaml` on `controlplane`.
- Wait for the API server to restart after saving the manifest.

<details>
<summary>Reference Answer Commands</summary>

```bash
vi /etc/kubernetes/manifests/kube-apiserver.yaml
# Set --authorization-mode=Node,RBAC
# Set --anonymous-auth=false
# Ensure NodeRestriction is included in --enable-admission-plugins
kubectl delete clusterrolebinding anonymous-admin-binding
watch crictl ps
kubectl --kubeconfig=/etc/kubernetes/admin.conf get --raw /readyz
curl -ks -o /dev/null -w '%{http_code}\n' https://127.0.0.1:6443/api
kubectl --kubeconfig=/etc/kubernetes/admin.conf get nodes
```

</details>

