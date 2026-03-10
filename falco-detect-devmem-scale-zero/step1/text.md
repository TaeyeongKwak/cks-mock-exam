Cluster security monitoring reported that a malicious container is trying to access `/dev/mem`.

Complete the following task:

1. Use Falco output to identify the flagged Pod and its Deployment.
2. Scale the offending Deployment to `0` replicas to stop the workload.

Notes

- Falco output is available from the running Pod in namespace `falco`.
- The affected application workload runs in namespace `runtime-lab`.
- Do not delete the Deployment. Scale it to `0`.
