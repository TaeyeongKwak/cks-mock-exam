The namespace `secure-lab` enforces the Pod Security Admission `restricted` profile.

The staged Deployment manifest `/root/masters/restricted-fix.yaml` violates that policy and cannot run as-is.

Complete the following task:

1. Edit `/root/masters/restricted-fix.yaml`.
2. Fix all Pod Security Admission `restricted` violations in the Deployment.
3. Apply the updated manifest so the Deployment runs successfully in namespace `secure-lab`.

Notes

- Keep the Deployment in namespace `secure-lab`.
- You only need to edit the staged manifest and apply it.

<details>
<summary>Reference Answer Commands</summary>

```bash
vi /root/masters/restricted-fix.yaml
# In spec.template.spec.securityContext, set:
# runAsNonRoot: true
# seccompProfile:
#   type: RuntimeDefault
#
# In the container securityContext, set:
# runAsUser: 1000
# runAsNonRoot: true
# allowPrivilegeEscalation: false
# capabilities:
#   drop:
#   - ALL
kubectl apply -f /root/masters/restricted-fix.yaml
kubectl rollout status deployment/policy-app -n secure-lab --timeout=180s
kubectl get pods -n secure-lab -o wide
```

</details>

