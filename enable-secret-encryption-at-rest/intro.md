This scenario rewrites a Kubernetes control plane hardening task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- The kube-apiserver runs as a static Pod.
- The API server manifest is `/etc/kubernetes/manifests/kube-apiserver.yaml`.

Success criteria

- kube-apiserver uses an `EncryptionConfiguration` manifest.
- The providers include `aescbc` first and `identity` after it.
- Secrets are encrypted in etcd instead of being stored in plaintext.
