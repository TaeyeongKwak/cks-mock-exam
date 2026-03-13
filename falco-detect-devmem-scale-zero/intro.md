This scenario practices runtime threat response in the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- A `falco` namespace is already present.
- A running Falco Pod is already recording output in namespace `falco`.
- Several workloads are running in namespace `runtime-lab`.
- One staged workload is repeatedly attempting to access `/dev/mem`.

Use Falco evidence to identify the bad workload, then apply the smallest correct remediation.

Success criteria

- You identify the malicious Pod and its Deployment from Falco output.
- You scale the flagged Deployment to `0`.
- The flagged Pod stops running.
