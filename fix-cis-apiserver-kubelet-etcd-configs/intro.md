This scenario covers a CIS-style hardening task on the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- The control plane runs as kubeadm static Pods.
- The main files you need are:
  - `/etc/kubernetes/manifests/kube-apiserver.yaml`
  - `/etc/kubernetes/manifests/etcd.yaml`
  - `/var/lib/kubelet/config.yaml`

Success criteria

- The API server no longer uses `AlwaysAllow` and includes both `Node` and `RBAC` authorization modes.
- The kubelet disables anonymous authentication and uses `Webhook` authorization.
- etcd enables `client-cert-auth`, disables `auto-tls`, and uses the kubeadm CA-signed certificate files.
