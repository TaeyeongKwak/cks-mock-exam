This scenario covers a kube-bench style hardening task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- The control plane runs as kubeadm static Pods.
- The files you may need are:
  - `/etc/kubernetes/manifests/kube-apiserver.yaml`
  - `/etc/kubernetes/manifests/etcd.yaml`
  - `/var/lib/kubelet/config.yaml`

Adaptation notes

- The original requirement mentions the `PodSecurityPolicy` admission plugin. Kubernetes removed PodSecurityPolicy in v1.25, so this scenario uses the built-in `PodSecurity` admission plugin instead.
- The original requirement mentions `RotateKubeletServerCertificate`. In the current kubelet configuration API, this is normalized to `serverTLSBootstrap: true`.
- The kubelet checks are scoped to the `controlplane` node, which is the machine you are using.

Success criteria

- The API server uses the `PodSecurity` admission plugin and sets `--kubelet-certificate-authority`.
- The kubelet disables anonymous authentication, uses `Webhook` authorization, and enables server TLS bootstrap.
- The etcd static Pod does not use `--auto-tls=true` or `--peer-auto-tls=true`.
