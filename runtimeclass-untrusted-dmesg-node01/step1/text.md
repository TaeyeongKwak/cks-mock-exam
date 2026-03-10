Deploy a Pod using a custom RuntimeClass.

Complete the following task:

1. Create a RuntimeClass named `sandbox-alt` using the prepared handler `runsc`.
2. Use `/opt/course/7/runtime-alt.yaml` for the RuntimeClass manifest.
3. Deploy Pod `guestbox` with image `alpine:3.18` in namespace `default`.
4. Ensure the Pod runs on worker node `node01`.
5. Ensure the Pod uses the `sandbox-alt` RuntimeClass.
6. Capture the output of `dmesg` from the running Pod into `/opt/course/7/guestbox-dmesg.log`.

Notes

- The source node `node-02` is normalized to `node01` in this environment.
- A helper Pod manifest is staged at `/opt/course/7/guestbox-pod.yaml`.
- Because Pod scheduling and runtime class settings are immutable in this scenario, recreate the Pod after editing if needed.
