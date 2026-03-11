An internal review tagged several standalone Pods in namespace `shipping` for retirement.

Task

- Remove every Pod in `shipping` that violates either of these rules:
  - it uses writable scratch storage through `emptyDir`
  - it runs privileged
  - it keeps the container root filesystem writable

Constraints

- Keep approved Pods running.
- Do not replace deleted Pods with new resources.
- Treat this as a cleanup job, not a refactor.

<details>
<summary>Reference Answer Commands</summary>

```bash
kubectl get pods -n shipping --show-labels
kubectl delete pod -n shipping -l lab.cleanup=remove
kubectl get pods -n shipping
kubectl wait --for=condition=Ready pod/ledger-api -n shipping --timeout=120s
kubectl wait --for=condition=Ready pod/metrics-sidecar -n shipping --timeout=120s
```

</details>

