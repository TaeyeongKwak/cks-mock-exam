Complete the following task:

1. Modify the `default` ServiceAccount in the `default` namespace to disable automatic token mounting.
2. Create a Secret of type `kubernetes.io/service-account-token` that references the `default` ServiceAccount.
3. Edit `/root/web-token-pod.yaml` so `web-token-pod`:
   - Uses the `default` ServiceAccount
   - Mounts the token from that Secret at `/var/run/secrets/kubernetes.io/serviceaccount/token`
4. Recreate the Pod if needed so the change takes effect.

Constraints

- Keep the Pod name as `web-token-pod`.
- Keep the Pod in namespace `default`.
