The `quarantine` namespace must become a dead-end segment.

Task

- Create a NetworkPolicy named `air-gap` in namespace `quarantine`.

Requirements

- It must apply to every Pod in `quarantine`.
- It must block all ingress.
- It must block all egress.

Constraints

- Do not modify Pods in `quarantine` or `edge`.
- Do not solve this with multiple policies.

<details>
<summary>Reference Answer Commands</summary>

```bash
cat <<'EOF' >/tmp/air-gap.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: air-gap
  namespace: quarantine
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress: []
  egress: []
EOF
kubectl apply -f /tmp/air-gap.yaml
kubectl exec -n quarantine inside-check -- sh -c 'wget -T 2 -qO- http://$(kubectl get pod vault-api -n quarantine -o jsonpath="{.status.podIP}"):8080/hostname' || true
kubectl exec -n edge edge-check -- sh -c 'wget -T 2 -qO- http://$(kubectl get pod vault-api -n quarantine -o jsonpath="{.status.podIP}"):8080/hostname' || true
```

</details>

