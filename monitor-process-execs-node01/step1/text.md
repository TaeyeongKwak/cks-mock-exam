Monitor container process execution behavior on worker node `node01`.

Prefer using the Falco binary and its default or custom rules on the node to observe process execution events, then write only the incidents you detect to the required report file.

Complete the following task:

1. Observe newly spawning and executing processes from containers on `node01` for at least 30 seconds.
2. Use Falco to monitor the events.
3. Save the detected incidents to `node01:/opt/node-01/reports/events`.

Required output format

- Each line must be:
  `timestamp,uid/username,processName`

Notes

- Run the monitoring on `node01`.
- Use the Falco binary directly on the node.
- The file must be created on `node01`, not on `controlplane`.
- The staged workloads continuously create new process execution events while the scenario is running.
- Falco is already available on `node01`.

Hints

- SSH to `node01`.
- Start Falco with output that helps you identify user and process information.
- Let it run long enough to collect staged events.
- Convert or filter the observed incidents into the required `timestamp,uid/username,processName` format.

<details>
<summary>Reference Answer Commands</summary>

```bash
ssh node01 'timeout 35 falco -A 2>/dev/null | awk -F[=| ] '\''/Notice|Warning|Error/ { ts=strftime("%Y-%m-%dT%H:%M:%S.000Z", systime(), 1); user="unknown"; proc="unknown"; for (i=1;i<=NF;i++) { if ($i ~ /^user$/ || $i ~ /^user.name$/) user=$(i+1); if ($i ~ /^proc.name$/ || $i ~ /^proc$/) proc=$(i+1); } if (proc != "unknown") print ts "," user "," proc; }'\'' > /opt/node-01/reports/events'
ssh node01 'cat /opt/node-01/reports/events'
kubectl rollout status deployment/root-spawner -n proc-watch --timeout=180s
kubectl rollout status deployment/uid1001-spawner -n proc-watch --timeout=180s
kubectl rollout status deployment/uid1002-spawner -n proc-watch --timeout=180s
```

The exact parsing command can vary. The key requirement is that you use Falco as the event source and save a clean report in the requested format.

</details>

