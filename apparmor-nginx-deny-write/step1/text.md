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

<details>
<summary>Reference Answer Commands</summary>

```bash
kubectl get nodes
ssh node01 'sudo apparmor_parser -r /root/cache-lockdown.apparmor'
vi /root/cache-probe.yaml
# keep the pod name cache-probe
# schedule it on node01
# attach the AppArmor profile cache-lockdown to the container
kubectl delete pod cache-probe --ignore-not-found
kubectl apply -f /root/cache-probe.yaml
kubectl wait --for=condition=Ready pod/cache-probe --timeout=180s
kubectl exec cache-probe -- sh -c 'touch /var/cache/demo/test-file' || true
kubectl get pod cache-probe -o wide
```

</details>

