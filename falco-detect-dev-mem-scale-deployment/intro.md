This scenario simulates runtime security monitoring for suspicious `/dev/mem` access.

Environment notes

- The terminal starts on `controlplane`.
- A suspicious Deployment named `mem-hacker` is running in namespace `default`.
- A Falco-compatible event stream is prepared at `/opt/falco-lab/falco-events.log`.
- If Falco is not preinstalled in the playground, a lightweight `falco` shim is provisioned for this lab.

Success criteria

- You create a custom Falco rule file at `/root/rule.yaml` to detect open-read/open-write attempts on `/dev/mem`.
- You use Falco output to identify the malicious Pod/Deployment.
- You scale Deployment `mem-hacker` in namespace `default` to `0` replicas.