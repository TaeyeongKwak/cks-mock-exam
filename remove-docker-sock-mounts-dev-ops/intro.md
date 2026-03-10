This scenario rewrites a Kubernetes workload hardening task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- The namespace `build-ops` already contains multiple Deployments.
- A helper manifest is staged at `/root/build-ops-workloads.yaml`.

Adaptation notes

- The default playground uses containerd, not Docker. To preserve the original exercise intent, this scenario stages a host file at `/var/run/docker.sock` and mounts it into the vulnerable Pods using a `hostPath`.
- In this scenario, "can access `/var/run/docker.sock`" means the file is present inside the container because of the hostPath mount.
- Updating the Deployment template will roll the Pods automatically.

Success criteria

- Every Deployment in namespace `build-ops` that mounts `/var/run/docker.sock` is updated to remove that mount.
- The rolled out Pods in `build-ops` can no longer access `/var/run/docker.sock`.
