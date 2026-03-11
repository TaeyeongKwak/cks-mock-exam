This scenario rewrites a RuntimeClass task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- The `runsc` runtime handler is prepared on `node01`.
- Helper manifests are staged under `/opt/course/7`.

Success criteria

- A RuntimeClass named `sandbox-alt` exists and uses handler `runsc`.
- Pod `guestbox` runs in namespace `default` on `node01`.
- Pod `guestbox` uses `runtimeClassName: sandbox-alt`.
- The output of `dmesg` from the running Pod is saved to `/opt/course/7/guestbox-dmesg.log`.
