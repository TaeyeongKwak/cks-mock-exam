This scenario rewrites a Kubernetes exam-style ServiceAccount token task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- A Pod named `web-token-pod` is already running in the `default` namespace.
- A reusable manifest for that Pod is staged at `/root/web-token-pod.yaml`.

Adaptation notes

- Updating the Pod requires recreating it, because the relevant Pod fields are not safely editable in place.
- You may delete and recreate `web-token-pod` after editing `/root/web-token-pod.yaml`.

Success criteria

- The `default` ServiceAccount in namespace `default` disables automatic token mounting.
- A Secret of type `kubernetes.io/service-account-token` references the `default` ServiceAccount.
- `web-token-pod` uses the `default` ServiceAccount.
- `web-token-pod` mounts the token from that Secret at `/var/run/secrets/kubernetes.io/serviceaccount/token`.
