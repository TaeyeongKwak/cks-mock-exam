The cluster already has a local image scanner webhook service, but the API server is not fully configured to use it.

Complete the following tasks:

1. Configure the ImagePolicyWebhook admission plugin using the webhook configuration files under `/etc/kubernetes/policyconfig/`.
2. Use the HTTPS webhook endpoint `https://valhalla.local:8081/image_policy`.
3. Enforce implicit deny so images are rejected unless explicitly allowed.
4. Enable any API server runtime setting required for the ImagePolicyWebhook integration to function.
5. Test the configuration with `/root/17/insecure-image.yaml`.

Notes

- The webhook service is already running on the control plane.
- Use the existing files in `/etc/kubernetes/policyconfig/` and complete the missing API server configuration.

<details>
<summary>Reference Answer Commands</summary>

```bash
vi /etc/kubernetes/policyconfig/webhook.kubeconfig
# Set the webhook server to https://valhalla.local:8081/image_policy
vi /etc/kubernetes/policyconfig/imagepolicyconfig.yaml
# Set defaultAllow: false and keep the staged webhook.kubeconfig reference
vi /etc/kubernetes/policyconfig/admission-config.yaml
# Add ImagePolicyWebhook and point it at imagepolicyconfig.yaml
vi /etc/kubernetes/manifests/kube-apiserver.yaml
# Add ImagePolicyWebhook to --enable-admission-plugins
# Add --admission-control-config-file=/etc/kubernetes/policyconfig/admission-config.yaml
# Add --runtime-config=imagepolicy.k8s.io/v1alpha1=true
watch crictl ps
kubectl get --raw /readyz
kubectl apply -f /root/17/insecure-image.yaml || true
```

</details>

