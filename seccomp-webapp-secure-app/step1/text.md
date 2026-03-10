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
