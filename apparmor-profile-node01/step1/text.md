Prepare the staged AppArmor setup for the web workload.

Tasks

1. Load the AppArmor profile from `node01:/root/web-guard.apparmor`.
2. Edit `/root/web-guard-pod.yaml` so the Pod uses that profile.
3. Run the Pod on `node01`.
4. Ensure the Pod reaches Running state with the profile applied.

Constraints

- Keep the Pod name `web-guard`.
- Use the staged profile name as-is.
- No extra Kubernetes resources are required for completion.

<details>
<summary>Reference Answer Commands</summary>

```bash
ssh node01 'apparmor_parser -r /root/web-guard.apparmor'
ssh node01 "grep '^web-guard ' /sys/kernel/security/apparmor/profiles"
vi /root/web-guard-pod.yaml
# Make sure the Pod stays named web-guard, is pinned to node01, and references the Localhost AppArmor profile web-guard.
# Either use spec.securityContext.appArmorProfile/container.securityContext.appArmorProfile,
# or set the legacy annotation container.apparmor.security.beta.kubernetes.io/web=localhost/web-guard.
kubectl apply -f /root/web-guard-pod.yaml
kubectl wait --for=condition=Ready pod/web-guard --timeout=120s
kubectl exec web-guard -- cat /proc/1/attr/current
```

</details>

