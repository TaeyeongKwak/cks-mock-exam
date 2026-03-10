There are Pods in namespace `build-ops` mounting `/var/run/docker.sock` from the host.

Complete the following task:

1. Identify the Pod or Pods in `build-ops` that mount `/var/run/docker.sock`.
2. Update their Deployment definitions to remove the mount.
3. Verify that the running containers can no longer access `/var/run/docker.sock`.

Notes

- A helper manifest for the current Deployments is staged at `/root/build-ops-workloads.yaml`.
- Update the Deployment template and let Kubernetes roll the Pods.
- Do not delete the safe Deployment that does not mount `docker.sock`.
