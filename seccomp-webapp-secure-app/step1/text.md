Harden the workload in namespace `secure-zone` with a custom seccomp profile.

Complete the following tasks:

1. Create a custom seccomp profile that includes the basic syscalls `read`, `write`, `exit`, and `sigreturn`.
2. Place the profile on `node01` under `/var/lib/kubelet/seccomp/frontend-seccomp.json`.
3. Edit `/root/frontend.yaml` so Deployment `frontend` uses this localhost seccomp profile.
4. Apply the Deployment and verify that the Pod is running with the seccomp profile enforced.

Notes

- A starter seccomp profile template is available at `/root/frontend-seccomp.json`.
- `Localhost` seccomp profiles are referenced relative to `/var/lib/kubelet/seccomp`.
- `frontend` is already pinned to `node01` so the profile only needs to exist on that node.

<details>
<summary>Reference Answer Commands</summary>

```bash
# Prepare the seccomp profile locally
vi /root/frontend-seccomp.json

# Use a profile shaped like this:
# {
#   "defaultAction": "SCMP_ACT_ERRNO",
#   "architectures": ["SCMP_ARCH_X86_64"],
#   "syscalls": [
#     {
#       "names": ["read", "write", "exit", "sigreturn"],
#       "action": "SCMP_ACT_ALLOW"
#     }
#   ]
# }

# Copy the profile to node01 under the kubelet seccomp directory
ssh node01 "mkdir -p /var/lib/kubelet/seccomp"
scp /root/frontend-seccomp.json node01:/var/lib/kubelet/seccomp/frontend-seccomp.json

# Edit the Deployment so it uses the localhost seccomp profile
vi /root/frontend.yaml

# In /root/frontend.yaml, set:
# spec.template.spec.nodeSelector.kubernetes.io/hostname: node01
# spec.template.spec.securityContext.seccompProfile.type: Localhost
# spec.template.spec.securityContext.seccompProfile.localhostProfile: frontend-seccomp.json

kubectl apply -f /root/frontend.yaml
kubectl rollout status deployment/frontend -n secure-zone --timeout=180s

# Final checks
POD=$(kubectl get pod -n secure-zone -l app=frontend -o jsonpath='{.items[0].metadata.name}')
ssh node01 "cat /var/lib/kubelet/seccomp/frontend-seccomp.json"
kubectl exec -n secure-zone "$POD" -- sh -c 'grep "^Seccomp:" /proc/1/status'
```

</details>

