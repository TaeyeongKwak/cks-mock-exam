This scenario rewrites a Falco process monitoring task for the default Killercoda Kubernetes playground.

Environment notes

- Start on `controlplane`.
- Falco is preinstalled on `node01` for this lab.
- The target single-container Pod `tomcat` runs on worker node `node01` in namespace `default`.
- The scored report file must stay on `node01` at `/home/anomalous/report`.

Success criteria

- Use Falco to monitor process activity from the `tomcat` container on `node01` for at least 40 seconds.
- Detect unusual newly spawned or executed commands.
- Save the detected incidents in bracket format: `[timestamp],[uid],[processName]`.
