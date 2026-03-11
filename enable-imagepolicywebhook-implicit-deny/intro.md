This scenario hardens image admission in the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- The kube-apiserver runs as a static Pod.
- The current webhook-related configuration is staged under `/etc/kubernetes/confcontrol`.
- A local TLS image scanner webhook is already prepared on `controlplane`, but the API server is not fully configured to use it.

Success criteria

- kube-apiserver enables the `ImagePolicyWebhook` admission plugin.
- kube-apiserver is configured to use the admission config from `/etc/kubernetes/confcontrol`.
- The image policy uses implicit deny for non-compliant images.
- Creating the staged Pod that uses a `latest` image tag is denied.
