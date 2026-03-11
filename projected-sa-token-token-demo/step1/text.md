Pod `jwt-demo` is running in namespace `default` and currently uses the default mounted ServiceAccount token.

Complete the following tasks:

1. Modify the `default` ServiceAccount so `automountServiceAccountToken` is set to `false`.
2. Edit `/root/jwt-demo.yaml` and ensure the Pod uses the `default` ServiceAccount.
3. Mount a manual projected ServiceAccount token so the token is available at `/var/run/secrets/tokens/token.jwt`.
4. Recreate the Pod if needed so the new configuration is applied.

Notes

- Use a projected volume, not a Secret volume.
- Keep the Pod name as `jwt-demo`.

<details>
<summary>Reference Answer Commands</summary>

```bash
kubectl patch serviceaccount default -n default -p '{"automountServiceAccountToken":false}'
vi /root/jwt-demo.yaml
# keep serviceAccountName: default
# add a projected volume with serviceAccountToken.path=token.jwt
# mount that volume at /var/run/secrets/tokens
kubectl delete pod jwt-demo -n default --ignore-not-found
kubectl apply -f /root/jwt-demo.yaml
kubectl wait --for=condition=Ready pod/jwt-demo -n default --timeout=180s
kubectl exec jwt-demo -- ls -l /var/run/secrets/tokens
```

</details>

