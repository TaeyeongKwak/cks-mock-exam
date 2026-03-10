This lab focuses on constraining container file writes with AppArmor in the default Killercoda cluster.

Prepared environment

- You begin on `controlplane`.
- The worker referenced by the original task is normalized to `node01`.
- A ready-to-load AppArmor profile is staged on `node01` at `/root/cache-lockdown.apparmor`.
- A Pod manifest template is staged on `controlplane` at `/root/cache-probe.yaml`.

Objective

- Load the staged AppArmor policy on `node01`.
- Update the Pod manifest so the workload uses that profile.
- Start the Pod on `node01`.
- Confirm that writes into `/var/cache/demo` are blocked from inside the container.
