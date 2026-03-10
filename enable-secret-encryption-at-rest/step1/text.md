By default, Kubernetes stores Secrets in etcd in plaintext, which is insecure.

Enable encryption at rest for Secrets.

Requirements

- Use an `EncryptionConfiguration` manifest.
- Configure the providers in this order:
  - `aescbc`
  - `identity`
- Ensure Secrets are encrypted in etcd.

Notes

- Edit `/etc/kubernetes/manifests/kube-apiserver.yaml` on `controlplane`.
- In this environment, place the encryption config at `/etc/kubernetes/pki/encryption-config.yaml`.
- A test Secret named `app-secret` already exists in namespace `default`.
- After enabling encryption, make sure `app-secret` is rewritten so it is stored encrypted in etcd.
