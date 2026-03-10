The cluster currently lacks ingress controls for the `tenant-a` application lane.

Build a NetworkPolicy named `tenant-http-only` in namespace `tenant-a` so that:

- connections coming from Pods in `tenant-a` can reach TCP port `80`
- traffic aimed at the alternate application port stays blocked
- Pods from `tenant-b` cannot open the allowed HTTP path

Constraints

- Keep the prepared namespaces and Pod names unchanged.
- Do not create extra namespaces or duplicate policies.
- The result should be enforced by Kubernetes networking, not by changing the Pods.
