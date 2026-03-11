Namespace `ops-blue` currently allows a Deployment named `debug-runner` to run a privileged Pod.

Complete the following task:

1. Configure namespace `ops-blue` to enforce the `restricted` Pod Security Standard using labels.
2. Delete the running Pod created by Deployment `debug-runner`.
3. Observe the ReplicaSet events that show why the Pod cannot be recreated.
4. Save the failure event lines to `node01:/opt/records/psa-fail.log`.

Notes

- Capture the event lines that show Pod Security Admission is blocking recreation.
- The log file must be created on `node01`, not on `controlplane`.
