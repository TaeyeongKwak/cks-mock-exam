This scenario covers a runtime process monitoring task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- The source worker node reference is normalized to the actual worker node `node01`.
- A single-container Pod named `tomcat` is already running on `node01`.
- The incident report must be created on `node01` at `/home/anomalous/report`.
- A helper manifest is staged at `/root/tomcat-pod.yaml`.

Adaptation notes

- The default playground does not ship Falco or Sysdig by default.
- To preserve the original monitoring objective, this scenario accepts Falco, Sysdig, or an equivalent process-monitoring approach.
- A helper watcher is staged on `node01` at `/usr/local/bin/tomcat-proc-watch` as one acceptable equivalent tool.
- In this scenario, the `tomcat` Pod periodically spawns unusual commands for longer than 40 seconds so you can observe them and record incidents.

Success criteria

- You monitor the `tomcat` Pod on `node01` for at least 40 seconds.
- You store incidents on `node01` at `/home/anomalous/report`.
- Each line uses the format `timestamp,uid,processName`.
- The report captures anomalous process executions from the `tomcat` container.
