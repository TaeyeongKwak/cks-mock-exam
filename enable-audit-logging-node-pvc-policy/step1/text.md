Enable Kubernetes audit logging with the required retention settings and extend the staged base policy.

Requirements

- Store audit logs at `/var/log/kubernetes-logs.log`.
- Retain logs for 5 days.
- Keep up to 10 old log files.
- Extend the audit policy at `/etc/kubernetes/pki/audit-policy.yaml` so that it:
  - Logs Node changes at `RequestResponse`
  - Logs PersistentVolumeClaim changes in namespace `portal` with the request body

Notes

- The staged base policy already contains only the exclusion rules. Extend it rather than replacing it with unrelated content.
- Edit `/etc/kubernetes/manifests/kube-apiserver.yaml` on `controlplane`.
- Wait for the kube-apiserver static Pod to restart after saving the manifest.

<details>
<summary>Reference Answer Commands</summary>

```bash
vi /etc/kubernetes/pki/audit-policy.yaml
# Keep the existing exclusion rules and omitStages.
# Add one rule with level: RequestResponse for core nodes.
# Add another rule with level: Request or RequestResponse for
# core persistentvolumeclaims in namespace portal.
vi /etc/kubernetes/manifests/kube-apiserver.yaml
# Set:
# --audit-policy-file=/etc/kubernetes/pki/audit-policy.yaml
# --audit-log-path=/var/log/kubernetes-logs.log
# --audit-log-maxage=5
# --audit-log-maxbackup=10
watch crictl ps
kubectl --kubeconfig=/etc/kubernetes/admin.conf get --raw /readyz
```

</details>

