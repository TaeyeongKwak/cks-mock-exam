Complete the following task:

1. Retrieve the contents of the existing Secret `root-admin` in namespace `vault`.
2. Store the decoded fields in local files:
   - `username` -> `/root/secret-lab/username.txt`
   - `password` -> `/root/secret-lab/password.txt`
3. Create a new Secret `app-secret` in namespace `vault` with:
   - `username=dbadmin`
   - `password=moresecurepas`
4. Create a Pod named `secret-mount-pod` in namespace `vault` that mounts Secret `app-secret`.

Constraints

- Both local files must be created during this task.
- Create the new Secret and Pod independently from the local files.

<details>
<summary>Reference Answer Commands</summary>

```bash
mkdir -p /root/secret-lab
kubectl get secret root-admin -n vault -o jsonpath='{.data.username}' | base64 -d > /root/secret-lab/username.txt
kubectl get secret root-admin -n vault -o jsonpath='{.data.password}' | base64 -d > /root/secret-lab/password.txt
kubectl create secret generic app-secret -n vault --from-literal=username=dbadmin --from-literal=password=moresecurepas --dry-run=client -o yaml | kubectl apply -f -
cat <<'EOF' >/tmp/secret-mount-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-mount-pod
  namespace: vault
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh","-c","sleep 3600"]
    volumeMounts:
    - name: app-secret
      mountPath: /etc/app-secret
  volumes:
  - name: app-secret
    secret:
      secretName: app-secret
EOF
kubectl apply -f /tmp/secret-mount-pod.yaml
kubectl wait --for=condition=Ready pod/secret-mount-pod -n vault --timeout=180s
```

</details>

