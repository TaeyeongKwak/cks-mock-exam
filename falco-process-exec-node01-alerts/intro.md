This scenario rewrites a Falco runtime detection task for the default Killercoda Kubernetes playground.

Environment notes

- Start on `controlplane` and perform host-level monitoring on `node01`.
- Falco is preinstalled on `node01` for this lab.
- A sample workload is staged in namespace `runtime-lab` to generate process activity.

Success criteria

- Use Falco to monitor newly spawning or executing processes in containers on `node01` for at least 30 seconds.
- Write detected incidents to `/opt/node-01/alerts/details` on `node01`.
- Each incident line must follow: `timestamp,uid/username,processName`.
