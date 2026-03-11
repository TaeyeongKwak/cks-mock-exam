Fix the security violations identified by kube-bench.

Requirements

- API server
  - Enable `RotateKubeletServerCertificate`
  - Enable admission plugin `PodSecurityPolicy`
  - Set the `--kubelet-certificate-authority` argument
- Kubelet
  - Disable anonymous authentication
  - Set `authorization-mode` to `Webhook`
- ETCD
  - Ensure `--auto-tls` is not `true`
  - Ensure `--peer-auto-tls` is not `true`

Notes

- Restart the kubelet after changing `/var/lib/kubelet/config.yaml`.
- Edit the control plane files directly on `controlplane`.

<details>
<summary>Reference Answer Commands</summary>

```bash
vi /etc/kubernetes/manifests/kube-apiserver.yaml
# Ensure --kubelet-certificate-authority=/etc/kubernetes/pki/ca.crt is present
# Ensure PodSecurity is not disabled in --disable-admission-plugins
vi /var/lib/kubelet/config.yaml
# Set serverTLSBootstrap: true
# Set authentication.anonymous.enabled: false
# Set authorization.mode: Webhook
systemctl restart kubelet
vi /etc/kubernetes/manifests/etcd.yaml
# Remove or change any --auto-tls=true and --peer-auto-tls=true settings
watch crictl ps
kubectl --kubeconfig=/etc/kubernetes/admin.conf get --raw /readyz
```

</details>

