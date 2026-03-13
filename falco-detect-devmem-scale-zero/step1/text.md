Cluster security monitoring reported that a malicious container is trying to access `/dev/mem`.

Inspect the Falco output first, identify the offending workload, and then take the smallest correct remediation action.

Complete the following task:

1. Use Falco output to identify the flagged Pod and its Deployment.
2. Scale the offending Deployment to `0` replicas to stop the workload.

Notes

- Falco output is available from the running Pod in namespace `falco`.
- The affected application workload runs in namespace `runtime-lab`.
- Do not delete the Deployment. Scale it to `0`.
- The suspicious workload continues attempting the same action until it is stopped.

Suggested approach

- First inspect Falco alerts.
- Extract the suspicious Pod and Deployment name from the alert fields.
- Confirm the workload in `runtime-lab`.
- Scale only the offending Deployment to zero.

<details>
<summary>Reference Answer Commands</summary>

```bash
kubectl logs -n falco pod/falco -c falco | grep '/dev/mem'
kubectl logs -n falco pod/falco -c falco | grep 'deployment=mem-reader'
kubectl scale deployment mem-reader -n runtime-lab --replicas=0
kubectl get deploy mem-reader -n runtime-lab
kubectl get pods -n runtime-lab -l app=mem-reader
```

The important part is not just the scale command. It is recognizing the right target from Falco output and avoiding changes to unrelated workloads.

</details>

