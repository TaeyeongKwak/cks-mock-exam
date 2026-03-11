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

<details>
<summary>Reference Answer Commands</summary>

```bash
ENC_KEY=$(head -c 32 /dev/urandom | base64)
cat <<EOF >/etc/kubernetes/pki/encryption-config.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
    - secrets
    providers:
    - aescbc:
        keys:
        - name: key1
          secret: ${ENC_KEY}
    - identity: {}
EOF
vi /etc/kubernetes/manifests/kube-apiserver.yaml
# Add --encryption-provider-config=/etc/kubernetes/pki/encryption-config.yaml
watch crictl ps
kubectl get --raw /readyz
kubectl get secret app-secret -n default -o yaml | kubectl replace -f -
ETCD_ID=$(crictl ps --name etcd -q | head -n1)
crictl exec "$ETCD_ID" etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt --key=/etc/kubernetes/pki/etcd/healthcheck-client.key get /registry/secrets/default/app-secret
```

</details>

