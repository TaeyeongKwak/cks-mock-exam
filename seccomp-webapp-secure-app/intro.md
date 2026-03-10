This scenario prepares namespace `secure-zone` with a Deployment named `frontend`.

Adaptation notes

- Kubernetes `Localhost` seccomp profiles must exist on the node filesystem under `/var/lib/kubelet/seccomp`, so the workload is pinned to `node01`.
- A literal four-syscall-only profile would prevent a normal web workload from starting in this playground. To keep the exercise solvable, a starter profile template is staged at `/root/frontend-seccomp.json`. It explicitly includes the requested basic syscalls and the extra runtime calls needed for the demo container to stay running.
- The learner still needs to place the profile on `node01` and configure the Deployment to use it.
