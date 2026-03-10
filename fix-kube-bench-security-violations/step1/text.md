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

- In this environment, `PodSecurityPolicy` is normalized to the built-in `PodSecurity` admission plugin because PodSecurityPolicy was removed in Kubernetes v1.25.
- In this environment, `RotateKubeletServerCertificate` is normalized to `serverTLSBootstrap: true` in `/var/lib/kubelet/config.yaml`.
- Restart the kubelet after changing `/var/lib/kubelet/config.yaml`.
- Edit the control plane files directly on `controlplane`.
