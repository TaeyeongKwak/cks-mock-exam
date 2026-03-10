This scenario practices runtime threat response in the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- A `falco` namespace is already present.
- Falco has already recorded an alert about a container trying to access `/dev/mem`.
- Several workloads are running in namespace `runtime-lab`.

Adaptation notes

- To keep the exercise deterministic on the default playground, Falco alert output is pre-staged and available through Pod logs in namespace `falco`.
- The flagged workload remains deployed so you can identify it from the alert and stop it.
- In this scenario, the remediation step is to scale the malicious Deployment to `0`.

Success criteria

- You identify the malicious Pod and its Deployment from Falco output.
- You scale the flagged Deployment to `0`.
- The flagged Pod stops running.
