This scenario rewrites a Kubernetes workload hardening task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- The namespace `build-ops` already contains multiple Deployments.
- A helper manifest is staged at `/root/build-ops-workloads.yaml`.

Success criteria

- Every Deployment in namespace `build-ops` that mounts `/var/run/docker.sock` is updated to remove that mount.
- The rolled out Pods in `build-ops` can no longer access `/var/run/docker.sock`.
