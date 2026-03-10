Monitor the single-container Pod `tomcat` for anomalous process activity.

Complete the following task:

1. Use Falco, Sysdig, or an equivalent monitoring approach to observe the `tomcat` Pod on worker node `node01`.
2. Detect processes that spawn or execute unusual commands over a period of at least 40 seconds.
3. Store the detected incidents on `node01` at `/home/anomalous/report`.

Required output format

- Each line must be:
  `timestamp,uid,processName`

Notes

- The report file must be created on `node01`, not on `controlplane`.
- A helper watcher is available on `node01` at `/usr/local/bin/tomcat-proc-watch` if you want to use it.
- A helper manifest for the staged Pod is available at `/root/tomcat-pod.yaml`.
