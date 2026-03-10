This scenario rewrites a Pod Security Admission response task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- The source node reference `cks-node` is normalized to the actual worker node `node01`.
- Namespace `ops-blue` already contains a Deployment named `debug-runner`.
- The log output file must be created on `node01` at `/opt/records/psa-fail.log`.

Adaptation notes

- The default playground uses Pod Security Admission labels rather than PodSecurityPolicy.
- The staged Deployment starts successfully before enforcement so you can confirm the namespace change is what blocks Pod recreation.
- The required failure evidence comes from ReplicaSet events after the existing Pod is deleted.

Success criteria

- Namespace `ops-blue` enforces the `restricted` Pod Security profile through labels.
- The running Pod from Deployment `debug-runner` is deleted.
- The ReplicaSet cannot recreate the Pod because Pod Security Admission blocks it.
- The failure event lines are saved on `node01` at `/opt/records/psa-fail.log`.
