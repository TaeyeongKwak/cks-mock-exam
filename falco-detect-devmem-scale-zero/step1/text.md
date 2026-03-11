Cluster security monitoring reported that a malicious container is trying to access `/dev/mem`.

Complete the following task:

1. Use Falco output to identify the flagged Pod and its Deployment.
2. Scale the offending Deployment to `0` replicas to stop the workload.

Notes

- Falco output is available from the running Pod in namespace `falco`.
- The affected application workload runs in namespace `runtime-lab`.
- Do not delete the Deployment. Scale it to `0`.

<details>
<summary>Reference Answer Commands</summary>

```bash
kubectl logs -n falco deploy/falco-monitor | grep '/dev/mem'
kubectl logs -n falco deploy/falco-monitor | grep 'deployment=mem-reader'
kubectl scale deployment mem-reader -n runtime-lab --replicas=0
kubectl get deploy mem-reader -n runtime-lab
kubectl get pods -n runtime-lab -l app=mem-reader
```

</details>

