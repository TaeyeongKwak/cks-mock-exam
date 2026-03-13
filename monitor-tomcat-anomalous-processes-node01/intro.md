This scenario covers a runtime process monitoring task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- A single-container Pod named `tomcat` is already running on `node01`.
- The incident report must be created on `node01` at `/home/anomalous/report`.
- A helper manifest is staged at `/root/tomcat-pod.yaml`.
- Falco is available on `node01`.

Run Falco on the node, observe suspicious execution activity, and produce the requested report.

Success criteria

- You monitor the `tomcat` Pod on `node01` for at least 40 seconds.
- You store incidents on `node01` at `/home/anomalous/report`.
- Each line uses the format `timestamp,uid,processName`.
- The report captures anomalous process executions from the `tomcat` container.
