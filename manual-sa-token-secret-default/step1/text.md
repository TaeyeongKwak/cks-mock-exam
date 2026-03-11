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

<details>
<summary>Reference Answer Commands</summary>

```bash
kubectl patch serviceaccount default -n default -p '{"automountServiceAccountToken":false}'
cat <<'EOF' >/tmp/default-sa-token.yaml
apiVersion: v1
kind: Secret
metadata:
  name: default-manual-token
  namespace: default
  annotations:
    kubernetes.io/service-account.name: default
type: kubernetes.io/service-account-token
EOF
kubectl apply -f /tmp/default-sa-token.yaml
vi /root/web-token-pod.yaml
# keep serviceAccountName: default
# mount secret default-manual-token
# expose the token at /var/run/secrets/kubernetes.io/serviceaccount/token
kubectl delete pod web-token-pod -n default --ignore-not-found
kubectl apply -f /root/web-token-pod.yaml
kubectl wait --for=condition=Ready pod/web-token-pod -n default --timeout=180s
```

</details>

