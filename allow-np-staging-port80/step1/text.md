The cluster currently lacks ingress controls for the `tenant-a` application lane.

Build a NetworkPolicy named `tenant-http-only` in namespace `tenant-a` so that:

- connections coming from Pods in `tenant-a` can reach TCP port `80`
- traffic aimed at the alternate application port stays blocked
- Pods from `tenant-b` cannot open the allowed HTTP path

Constraints

- Keep the prepared namespaces and Pod names unchanged.
- Do not create extra namespaces or duplicate policies.
- The result should be enforced by Kubernetes networking, not by changing the Pods.

<details>
<summary>Reference Answer Commands</summary>

```bash
cat <<'EOF' >/tmp/tenant-http-only.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: tenant-http-only
  namespace: tenant-a
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}
    ports:
    - protocol: TCP
      port: 80
EOF
kubectl apply -f /tmp/tenant-http-only.yaml
kubectl exec -n tenant-a local-probe -- sh -c 'wget -qO- --timeout=3 http://$(kubectl get pod catalog-http -n tenant-a -o jsonpath="{.status.podIP}"):80'
kubectl exec -n tenant-a local-probe -- sh -c 'wget -qO- --timeout=3 http://$(kubectl get pod catalog-admin -n tenant-a -o jsonpath="{.status.podIP}"):8080' || true
kubectl exec -n tenant-b remote-probe -- sh -c 'wget -qO- --timeout=3 http://$(kubectl get pod catalog-http -n tenant-a -o jsonpath="{.status.podIP}"):80' || true
```

</details>

