This lab targets AppArmor profile activation on the standard Killercoda Kubernetes playground.

Prepared environment

- You begin on `controlplane`.
- A ready-made AppArmor profile is staged on `node01` at `/root/web-guard.apparmor`.
- A Pod manifest template is staged on `controlplane` at `/root/web-guard-pod.yaml`.

Target outcome

- Import the staged profile on `node01`.
- Update the Pod manifest so the workload uses that profile.
- Start the Pod on `node01`.
- Confirm that the container is actually running with the intended AppArmor profile.
