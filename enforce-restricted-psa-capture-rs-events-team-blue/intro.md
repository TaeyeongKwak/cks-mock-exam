This scenario rewrites a Pod Security Admission response task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- Namespace `ops-blue` already contains a Deployment named `debug-runner`.
- The log output file must be created on `node01` at `/opt/records/psa-fail.log`.

Success criteria

- Namespace `ops-blue` enforces the `restricted` Pod Security profile through labels.
- The running Pod from Deployment `debug-runner` is deleted.
- The ReplicaSet cannot recreate the Pod because Pod Security Admission blocks it.
- The failure event lines are saved on `node01` at `/opt/records/psa-fail.log`.
