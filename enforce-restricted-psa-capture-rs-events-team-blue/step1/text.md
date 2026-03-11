Namespace `ops-blue` currently allows a Deployment named `debug-runner` to run a privileged Pod.

Complete the following task:

1. Configure namespace `ops-blue` to enforce the `restricted` Pod Security Standard using labels.
2. Delete the running Pod created by Deployment `debug-runner`.
3. Observe the ReplicaSet events that show why the Pod cannot be recreated.
4. Save the failure event lines to `node01:/opt/records/psa-fail.log`.

Notes

- Capture the event lines that show Pod Security Admission is blocking recreation.
- The log file must be created on `node01`, not on `controlplane`.

<details>
<summary>Reference Answer Commands</summary>

```bash
# Enforce the restricted Pod Security Standard on the namespace
kubectl label namespace ops-blue \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/enforce-version=latest \
  --overwrite

# Remove the currently running Pod so the ReplicaSet tries to recreate it
kubectl get pods -n ops-blue -l app=debug-runner
kubectl delete pod -n ops-blue -l app=debug-runner

# Wait briefly, then inspect the ReplicaSet failure events
sleep 10
kubectl get rs -n ops-blue -l app=debug-runner
RS_NAME=$(kubectl get rs -n ops-blue -l app=debug-runner -o jsonpath='{.items[0].metadata.name}')
kubectl describe rs "$RS_NAME" -n ops-blue

# Save the admission failure lines on node01
ssh node01 "mkdir -p /opt/records"
kubectl describe rs "$RS_NAME" -n ops-blue | grep -E 'FailedCreate|PodSecurity|restricted|privileged|allowPrivilegeEscalation|capabilities' | ssh node01 "cat > /opt/records/psa-fail.log"

# Final checks
kubectl get pods -n ops-blue -l app=debug-runner
ssh node01 "cat /opt/records/psa-fail.log"
```

</details>

