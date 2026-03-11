Create a new Kubernetes client identity and namespace-scoped access rule set.

Tasks

1. Generate a private key and CSR for user `marie`.
2. Create a Kubernetes CSR object named `marie-access` and approve it.
3. Retrieve the signed certificate and save it locally.
4. Create a Role named `tenant-editor` in namespace `tenant-user` that allows `list`, `get`, `create`, and `delete` on `pods` and `secrets`.
5. Create a RoleBinding named `tenant-editor-bind` that binds that Role to user `marie`.
6. Verify the granted access.

Notes

- A suggested workspace is available at `/srv/cert-lab`.
- Keep the namespace `tenant-user`.
- Keep the Role and RoleBinding names exactly as requested.

<details>
<summary>Reference Answer Commands</summary>

```bash
mkdir -p /srv/cert-lab
cd /srv/cert-lab
openssl genrsa -out marie.key 2048
openssl req -new -key marie.key -out marie.csr -subj "/CN=marie"
cat <<EOF > marie-access.yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: marie-access
spec:
  request: $(base64 -w0 < marie.csr)
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
EOF
kubectl apply -f marie-access.yaml
kubectl certificate approve marie-access
kubectl get csr marie-access -o jsonpath='{.status.certificate}' | base64 -d > marie.crt
kubectl create role tenant-editor -n tenant-user --verb=list,get,create,delete --resource=pods,secrets --dry-run=client -o yaml | kubectl apply -f -
kubectl create rolebinding tenant-editor-bind -n tenant-user --role=tenant-editor --user=marie --dry-run=client -o yaml | kubectl apply -f -
kubectl auth can-i create pods -n tenant-user --as=marie
kubectl auth can-i delete secrets -n tenant-user --as=marie
```

</details>

