This scenario rewrites a RuntimeClass task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- The source node name `node-02` is normalized to the actual worker node `node01`.
- The `runsc` runtime handler is prepared on `node01`.
- Helper manifests are staged under `/opt/course/7`.

Adaptation notes

- The default playground has only one worker node, so the requested worker placement is mapped to `node01`.
- The output file path is preserved as `/opt/course/7/guestbox-dmesg.log`.
- A helper Pod manifest is staged at `/opt/course/7/guestbox-pod.yaml`, and a RuntimeClass manifest path is reserved at `/opt/course/7/runtime-alt.yaml`.

Success criteria

- A RuntimeClass named `sandbox-alt` exists and uses handler `runsc`.
- Pod `guestbox` runs in namespace `default` on `node01`.
- Pod `guestbox` uses `runtimeClassName: sandbox-alt`.
- The output of `dmesg` from the running Pod is saved to `/opt/course/7/guestbox-dmesg.log`.
