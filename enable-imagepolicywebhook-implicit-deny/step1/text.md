The cluster has a container image scanner webhook, but the API server configuration is incomplete.

Complete the following task:

1. Finish the configuration under `/etc/kubernetes/confcontrol`.
2. Enable the `ImagePolicyWebhook` admission plugin in kube-apiserver.
3. Configure the image policy to use implicit deny for non-compliant images.
4. Test the setup by attempting to deploy the staged Pod manifest `/root/latest-deny-pod.yaml`, which uses the `latest` image tag.

Requirements

- The kube-apiserver must use the admission config from `/etc/kubernetes/confcontrol/admission-config.yaml`.
- The image policy must deny when the webhook reports a non-compliant image.
- The staged Pod using `nginx:latest` must be rejected.

Notes

- If you change the kube-apiserver static Pod manifest, wait for the API server to restart.
- The local webhook backend is already running on `controlplane`.
