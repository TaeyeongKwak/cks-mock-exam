This scenario practices runtime threat response in the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- A `falco` namespace is already present.
- Falco has already recorded an alert about a container trying to access `/dev/mem`.
- Several workloads are running in namespace `runtime-lab`.

Success criteria

- You identify the malicious Pod and its Deployment from Falco output.
- You scale the flagged Deployment to `0`.
- The flagged Pod stops running.
