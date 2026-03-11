#!/bin/bash
set -euo pipefail

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

cat <<'EOF' >/root/frontend-seccomp.json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "defaultErrnoRet": 1,
  "archMap": [
    {
      "architecture": "SCMP_ARCH_X86_64",
      "subArchitectures": [
        "SCMP_ARCH_X86",
        "SCMP_ARCH_X32"
      ]
    }
  ],
  "syscalls": [
    {
      "names": [
        "read",
        "write",
        "exit",
        "sigreturn",
        "rt_sigreturn",
        "exit_group",
        "brk",
        "close",
        "clock_nanosleep",
        "epoll_create1",
        "epoll_ctl",
        "epoll_pwait",
        "execve",
        "futex",
        "getpid",
        "getrandom",
        "mmap",
        "mprotect",
        "munmap",
        "nanosleep",
        "newfstatat",
        "openat",
        "prctl",
        "pread64",
        "readlink",
        "rseq",
        "rt_sigaction",
        "rt_sigprocmask",
        "sched_getaffinity",
        "set_robust_list",
        "set_tid_address",
        "statx"
      ],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
EOF

cat <<'EOF' >/root/frontend.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: secure-zone
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      nodeSelector:
        kubernetes.io/hostname: node01
      containers:
      - name: frontend
        image: busybox:1.36
        command:
        - sh
        - -c
        - sleep 3600
EOF

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: secure-zone
EOF

kubectl delete deployment frontend -n secure-zone --ignore-not-found >/dev/null
kubectl apply -f /root/frontend.yaml >/dev/null
kubectl rollout status deployment/frontend -n secure-zone --timeout=180s >/dev/null

ssh node01 "mkdir -p /var/lib/kubelet/seccomp && rm -f /var/lib/kubelet/seccomp/frontend-seccomp.json" >/dev/null
