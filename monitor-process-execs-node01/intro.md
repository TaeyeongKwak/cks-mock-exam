This scenario rewrites a runtime process monitoring task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- The incident output path remains `/opt/node-01/reports/events`, and it must be created on `node01`.
- Several Pods pinned to `node01` are already generating new child processes over time.

Success criteria

- You monitor container process execution activity on `node01` for at least 30 seconds.
- You save incidents to `node01:/opt/node-01/reports/events`.
- Each incident line uses the format `timestamp,uid/username,processName`.
