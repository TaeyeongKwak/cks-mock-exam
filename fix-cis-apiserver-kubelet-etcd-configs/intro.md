This scenario covers a CIS-style hardening task on the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- The control plane runs as kubeadm static Pods.
- The main files you need are:
  - `/etc/kubernetes/manifests/kube-apiserver.yaml`
  - `/etc/kubernetes/manifests/etcd.yaml`
  - `/var/lib/kubelet/config.yaml`

Adaptation notes

- The kubelet checks are scoped to the `controlplane` node, which is the node you are working on.
- For etcd, "valid TLS certificates (not self-signed)" is normalized to using the default kubeadm CA-signed certificate files under `/etc/kubernetes/pki/etcd`.
- The staged insecure state is built by changing flags and kubelet config values, while keeping the cluster recoverable.

Success criteria

- The API server no longer uses `AlwaysAllow` and includes both `Node` and `RBAC` authorization modes.
- The kubelet disables anonymous authentication and uses `Webhook` authorization.
- etcd enables `client-cert-auth`, disables `auto-tls`, and uses the kubeadm CA-signed certificate files.
