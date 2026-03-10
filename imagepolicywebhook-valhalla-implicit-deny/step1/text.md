The cluster already has a local image scanner webhook service, but the API server is not fully configured to use it.

Complete the following tasks:

1. Configure the ImagePolicyWebhook admission plugin using the webhook configuration files under `/etc/kubernetes/policyconfig/`.
2. Use the HTTPS webhook endpoint `https://valhalla.local:8081/image_policy`.
3. Enforce implicit deny so images are rejected unless explicitly allowed.
4. Test the configuration with `/root/17/insecure-image.yaml`.

Notes

- The webhook service is already running on the control plane.
- Use the existing files in `/etc/kubernetes/policyconfig/` and complete the missing API server configuration.
