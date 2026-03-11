Fix the staged CIS Benchmark findings by updating the configuration files and restarting affected components.

Violations to fix

- API Server
  - `authorization-mode` must not be `AlwaysAllow`
  - It must include `Node`
  - It must include `RBAC`
- Kubelet
  - Anonymous authentication must be disabled
  - Authorization mode must use `Webhook`
- etcd
  - `--client-cert-auth` must be enabled
  - `--auto-tls` must not be enabled
  - Valid TLS certificates must be used instead of self-signed certificates

Notes

- Edit the files directly on `controlplane`.
- Restart the kubelet after changing `/var/lib/kubelet/config.yaml`.
- Static Pod changes take effect when the manifest files are updated.

<details>
<summary>Reference Answer Commands</summary>

```bash
vi /etc/kubernetes/manifests/kube-apiserver.yaml
# Replace AlwaysAllow with Node,RBAC
vi /var/lib/kubelet/config.yaml
# Set authentication.anonymous.enabled: false and authorization.mode: Webhook
systemctl restart kubelet
vi /etc/kubernetes/manifests/etcd.yaml
# Set --client-cert-auth=true, remove or disable --auto-tls=true, and use:
# --cert-file=/etc/kubernetes/pki/etcd/server.crt
# --key-file=/etc/kubernetes/pki/etcd/server.key
# --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
watch crictl ps
kubectl --kubeconfig=/etc/kubernetes/admin.conf get --raw /readyz
kubectl --kubeconfig=/etc/kubernetes/admin.conf get --raw '/api/v1/nodes/controlplane/proxy/configz'
```

</details>

