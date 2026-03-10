This scenario stages an incomplete ImagePolicyWebhook setup for the cluster.

Adaptation notes

- The webhook configuration directory is prepared at `/etc/kubernetes/policyconfig`.
- A local HTTPS image policy service is staged on the control plane and must be wired into the API server.
- The test manifest to validate the policy is staged at `/root/17/insecure-image.yaml`.
