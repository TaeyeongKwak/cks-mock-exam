Deployment `docker-ops` in namespace `sandbox-lab` mounts `/var/run/docker.sock` from the host.

This is risky because access to the Docker socket can be used for privilege escalation.

Instead of deleting the workload or removing the mount, harden the Deployment with Kubernetes security settings.

Complete the following task:

1. Edit `/root/sandbox/docker-ops.yaml`.
2. Ensure the Pod does not run as root.
3. Drop all Linux capabilities except those required.
4. Enforce a read-only filesystem where possible.
5. Apply the updated manifest so Deployment `docker-ops` rolls out successfully in namespace `sandbox-lab`.

Notes

- Keep the Deployment name and namespace unchanged.
- Keep the `/var/run/docker.sock` mount in place.
- The container only runs `sleep 3600`, so it does not need any added Linux capabilities.
- The terminal starts on `controlplane`.

<details>
<summary>Reference Answer Commands</summary>

```bash
vi /root/sandbox/docker-ops.yaml
# set runAsNonRoot: true
# set runAsUser to a non-root uid
# set allowPrivilegeEscalation: false
# set readOnlyRootFilesystem: true
# drop all capabilities and do not add any back
kubectl apply -f /root/sandbox/docker-ops.yaml
kubectl rollout status deployment/docker-ops -n sandbox-lab --timeout=180s
kubectl get deployment docker-ops -n sandbox-lab -o yaml
```

</details>

