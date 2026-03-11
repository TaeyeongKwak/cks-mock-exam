The cluster uses containerd with `runc` as the default runtime and has been prepared with an additional runtime handler `runsc`.

Complete the following task:

1. Create a `RuntimeClass` named `isolated` using handler `runsc`.
2. Use the file path `/root/10/isolated-class.yaml` for the RuntimeClass manifest.
3. Update all Pods in namespace `backend` to use this RuntimeClass.

Notes

- A helper manifest for the existing Pods is staged at `/root/10/backend-pods.yaml`.
- Because `runtimeClassName` changes require Pod recreation in this scenario, you may delete and recreate the Pods after editing the helper manifest.

<details>
<summary>Reference Answer Commands</summary>

```bash
cat <<'EOF' >/root/10/isolated-class.yaml
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: isolated
handler: runsc
EOF
vi /root/10/backend-pods.yaml
# add runtimeClassName: isolated under each Pod spec
kubectl delete pod svc-a svc-b -n backend --ignore-not-found
kubectl apply -f /root/10/isolated-class.yaml
kubectl apply -f /root/10/backend-pods.yaml
kubectl wait --for=condition=Ready pod/svc-a -n backend --timeout=180s
kubectl wait --for=condition=Ready pod/svc-b -n backend --timeout=180s
kubectl get runtimeclass isolated -o yaml
```

</details>

