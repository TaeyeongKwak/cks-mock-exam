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
