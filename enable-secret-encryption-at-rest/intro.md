This scenario rewrites a Kubernetes control plane hardening task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- The kube-apiserver runs as a static Pod.
- The API server manifest is `/etc/kubernetes/manifests/kube-apiserver.yaml`.
- In this environment, the encryption config path is normalized to `/etc/kubernetes/pki/encryption-config.yaml` because that directory is already mounted into the kube-apiserver static Pod.

Adaptation notes

- A test Secret named `app-secret` is staged in the `default` namespace so the scenario can verify encryption directly in etcd.
- Enabling encryption at rest only affects new writes. After you enable the feature, make sure the staged Secret is rewritten so it is stored encrypted in etcd.

Success criteria

- kube-apiserver uses an `EncryptionConfiguration` manifest.
- The providers include `aescbc` first and `identity` after it.
- Secrets are encrypted in etcd instead of being stored in plaintext.
