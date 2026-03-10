Set up the staged AppArmor restriction for the probe workload.

Tasks

1. Load the AppArmor profile from `node01:/root/cache-lockdown.apparmor`.
2. Edit `/root/cache-probe.yaml` so the Pod uses that profile.
3. Run the Pod on `node01`.
4. Make sure the running container cannot create or overwrite files in `/var/cache/demo`.

Constraints

- Keep the Pod name `cache-probe`.
- Do not replace the staged profile with a different profile name.
- You only need the resources required to demonstrate the write block.
