Create a NetworkPolicy named `ingress-guard` in namespace `app-team` to restrict access to Pod `catalog-service`.

Requirements

- Allow ingress from Pods in the same namespace `app-team`.
- Allow ingress from Pods with label `environment=testing` in any namespace.
- Do not allow other ingress traffic.

Notes

- The target Pod `catalog-service` is already running in `app-team`.
- Test client Pods are already running in `app-team`, `qa-lab`, and `misc-team`.
- You only need to create the NetworkPolicy.

<details>
<summary>Reference Answer Commands</summary>

```bash
cat <<'EOF' >/tmp/ingress-guard.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ingress-guard
  namespace: app-team
spec:
  podSelector:
    matchLabels:
      app: catalog-service
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}
  - from:
    - namespaceSelector: {}
      podSelector:
        matchLabels:
          environment: testing
EOF
kubectl apply -f /tmp/ingress-guard.yaml
kubectl exec -n app-team same-ns-client -- sh -c 'wget -qO- --timeout=3 http://$(kubectl get pod catalog-service -n app-team -o jsonpath="{.status.podIP}"):5678'
kubectl exec -n qa-lab testing-client -- sh -c 'wget -qO- --timeout=3 http://$(kubectl get pod catalog-service -n app-team -o jsonpath="{.status.podIP}"):5678'
kubectl exec -n misc-team denied-client -- sh -c 'wget -qO- --timeout=3 http://$(kubectl get pod catalog-service -n app-team -o jsonpath="{.status.podIP}"):5678' || true
```

</details>

