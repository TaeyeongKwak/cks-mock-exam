This lab presents a namespace-isolation exercise for the default Killercoda Kubernetes environment.

Lab setup

- You start on `controlplane`.
- Two namespaces are already prepared: `tenant-a` and `tenant-b`.
- `tenant-a` contains an internal probe Pod plus two HTTP services exposed by plain Pods.
- `tenant-b` contains a probe Pod that represents traffic coming from another tenant.

Scenario notes

- The application team wants traffic inside `tenant-a` to reach only the shared HTTP endpoint on TCP `80`.
- Access to the alternate service port must stay blocked.
- Requests originating outside `tenant-a` must also be blocked.

Completion target

- A single NetworkPolicy in `tenant-a` enforces the intended ingress boundary.
- The internal probe can still reach the HTTP service on port `80`.
- The alternate port and cross-namespace source both remain denied.
