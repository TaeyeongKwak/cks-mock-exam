This scenario rewrites a runtime process monitoring task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- The source worker node reference `node-01` is normalized to the actual worker node `node01`.
- The incident output path remains `/opt/node-01/reports/events`, and it must be created on `node01`.
- Several Pods pinned to `node01` are already generating new child processes over time.

Adaptation notes

- The default playground does not ship Falco, so this scenario accepts any equivalent process execution monitoring approach.
- A helper tool is staged on `node01` at `/usr/local/bin/container-proc-watch` as one acceptable "similar tool".
- The staged workloads generate process execution events over time so you can observe them for at least 30 seconds and record incidents.

Success criteria

- You monitor container process execution activity on `node01` for at least 30 seconds.
- You save incidents to `node01:/opt/node-01/reports/events`.
- Each incident line uses the format `timestamp,uid/username,processName`.
