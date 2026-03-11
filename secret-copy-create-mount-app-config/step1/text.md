Complete the following task:

1. Retrieve the `ca.crt` data from the existing Secret `default-token-alpha` in namespace `dev-sec`.
2. Save that decoded data to `/root/cluster-ca.crt`.
3. Create a Secret named `web-config-secret` in namespace `portal` with:
   - `APP_USER=appadmin`
   - `APP_PASS=Sup3rS3cret`
4. Deploy a Pod named `web-config-pod` in namespace `portal` using the `nginx` image.
5. Mount Secret `web-config-secret` into the Pod at `/etc/app-config`.

Notes

- A helper manifest is staged at `/root/web-config-pod.yaml`.
- Keep the Pod name exactly `web-config-pod`.
- Create the new Secret independently from the local `ca.crt` file.

<details>
<summary>Reference Answer Commands</summary>

```bash
kubectl get secret default-token-alpha -n dev-sec -o jsonpath='{.data.ca\.crt}' | base64 -d > /root/cluster-ca.crt
kubectl create secret generic web-config-secret -n portal --from-literal=APP_USER=appadmin --from-literal=APP_PASS=Sup3rS3cret --dry-run=client -o yaml | kubectl apply -f -
vi /root/web-config-pod.yaml
# keep the pod name web-config-pod
# set secretName: web-config-secret
# mount the secret at /etc/app-config
kubectl apply -f /root/web-config-pod.yaml
kubectl wait --for=condition=Ready pod/web-config-pod -n portal --timeout=180s
kubectl exec -n portal web-config-pod -- cat /etc/app-config/APP_USER
kubectl exec -n portal web-config-pod -- cat /etc/app-config/APP_PASS
```

</details>

