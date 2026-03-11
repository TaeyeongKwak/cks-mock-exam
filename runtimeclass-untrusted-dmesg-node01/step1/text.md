Deploy a Pod using a custom RuntimeClass.

Complete the following task:

1. Create a RuntimeClass named `sandbox-alt` using the prepared handler `runsc`.
2. Use `/opt/course/7/runtime-alt.yaml` for the RuntimeClass manifest.
3. Deploy Pod `guestbox` with image `alpine:3.18` in namespace `default`.
4. Ensure the Pod runs on worker node `node01`.
5. Ensure the Pod uses the `sandbox-alt` RuntimeClass.
6. Capture the output of `dmesg` from the running Pod into `/opt/course/7/guestbox-dmesg.log`.

Notes

- A helper Pod manifest is staged at `/opt/course/7/guestbox-pod.yaml`.
- Because Pod scheduling and runtime class settings are immutable in this scenario, recreate the Pod after editing if needed.

<details>
<summary>Reference Answer Commands</summary>

```bash
cat <<'EOF' >/opt/course/7/runtime-alt.yaml
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: sandbox-alt
handler: runsc
EOF
vi /opt/course/7/guestbox-pod.yaml
# add runtimeClassName: sandbox-alt
kubectl delete pod guestbox -n default --ignore-not-found
kubectl apply -f /opt/course/7/runtime-alt.yaml
kubectl apply -f /opt/course/7/guestbox-pod.yaml
kubectl wait --for=condition=Ready pod/guestbox -n default --timeout=180s
kubectl exec guestbox -- dmesg > /opt/course/7/guestbox-dmesg.log
kubectl get runtimeclass sandbox-alt -o yaml
```

</details>

