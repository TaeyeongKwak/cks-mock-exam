There are Pods in namespace `build-ops` mounting `/var/run/docker.sock` from the host.

Complete the following task:

1. Identify the Pod or Pods in `build-ops` that mount `/var/run/docker.sock`.
2. Update their Deployment definitions to remove the mount.
3. Verify that the running containers can no longer access `/var/run/docker.sock`.

Notes

- A helper manifest for the current Deployments is staged at `/root/build-ops-workloads.yaml`.
- Update the Deployment template and let Kubernetes roll the Pods.
- Do not delete the safe Deployment that does not mount `docker.sock`.

<details>
<summary>Reference Answer Commands</summary>

```bash
grep -n '/var/run/docker.sock' /root/build-ops-workloads.yaml
vi /root/build-ops-workloads.yaml
# remove the docker.sock volumeMount and hostPath volume from the vulnerable deployments only
# keep api-gateway unchanged
kubectl apply -f /root/build-ops-workloads.yaml
kubectl rollout status deployment/job-runner -n build-ops --timeout=180s
kubectl rollout status deployment/image-scan -n build-ops --timeout=180s
kubectl get pods -n build-ops -o wide
```

</details>

