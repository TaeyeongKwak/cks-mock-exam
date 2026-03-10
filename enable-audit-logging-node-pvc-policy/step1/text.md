Enable Kubernetes audit logging with the required retention settings and extend the staged base policy.

Requirements

- Store audit logs at `/var/log/kubernetes-logs.log`.
- Retain logs for 5 days.
- Keep up to 10 old log files.
- Extend the audit policy at `/etc/kubernetes/pki/audit-policy.yaml` so that it:
  - Logs Node changes at `RequestResponse`
  - Logs PersistentVolumeClaim changes in namespace `portal` with the request body

Notes

- The source base policy path `/etc/audit/audit-policy.yaml` is normalized to `/etc/kubernetes/pki/audit-policy.yaml` in this playground.
- The staged base policy already contains only the exclusion rules. Extend it rather than replacing it with unrelated content.
- Edit `/etc/kubernetes/manifests/kube-apiserver.yaml` on `controlplane`.
- Wait for the kube-apiserver static Pod to restart after saving the manifest.
