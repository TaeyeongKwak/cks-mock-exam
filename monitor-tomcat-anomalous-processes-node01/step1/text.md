Monitor the single-container Pod `tomcat` for anomalous process activity.

Run Falco on the node, observe the `tomcat` container long enough to catch unusual process executions, and save only the relevant incidents in the required format.

Complete the following task:

1. Use Falco to observe the `tomcat` Pod on worker node `node01`.
2. Detect processes that spawn or execute unusual commands over a period of at least 40 seconds.
3. Store the detected incidents on `node01` at `/home/anomalous/report`.

Required output format

- Each line must be:
  `timestamp,uid,processName`

Notes

- The report file must be created on `node01`, not on `controlplane`.
- Use the Falco binary directly on `node01`.
- A helper manifest for the staged Pod is available at `/root/tomcat-pod.yaml`.
- Falco is already available on `node01`.

Hints

- Ensure the staged `tomcat` Pod is running on `node01`.
- Start Falco on `node01` and watch process execution events long enough to capture anomalies.
- Extract only the timestamp, uid, and process name into the final report.

<details>
<summary>Reference Answer Commands</summary>

```bash
kubectl apply -f /root/tomcat-pod.yaml
kubectl wait --for=condition=Ready pod/tomcat --timeout=180s
ssh node01 'timeout 45 falco -A 2>/dev/null | awk -F[=| ] '\''/Notice|Warning|Error/ { ts=strftime("%Y-%m-%dT%H:%M:%S.000Z", systime(), 1); uid="0"; proc="unknown"; for (i=1;i<=NF;i++) { if ($i ~ /^user.uid$/ || $i ~ /^uid$/) uid=$(i+1); if ($i ~ /^proc.name$/ || $i ~ /^proc$/) proc=$(i+1); } if (proc != "unknown") print ts "," uid "," proc; }'\'' > /home/anomalous/report'
ssh node01 'cat /home/anomalous/report'
```

The exact filtering can vary. The key requirement is that Falco is the event source and the final report matches the requested format.

</details>

