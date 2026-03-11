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
