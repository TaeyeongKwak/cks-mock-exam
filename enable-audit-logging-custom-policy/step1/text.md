The platform team wants a usable audit stream again.

Work on `controlplane` and repair both the static Pod flags and the seeded policy file.

Files

- API server manifest: `/etc/kubernetes/manifests/kube-apiserver.yaml`
- Seed policy: `/etc/kubernetes/pki/ops-audit-rules.yaml`

Required end state

- Audit output goes to `/var/log/kubernetes-logs.log`
- Rotation keeps 5 days, 10 backups, and 100 MB per file
- The policy keeps the existing probe-endpoint exclusion
- The policy adds:
  - `RequestResponse` for CronJobs
  - request-body logging for `kube-system` Deployments
  - `Request` for the remaining core and `extensions` resources
  - a `None` rule for `system:kube-proxy` `watch` calls on `endpoints` or `services`

Wait for the API server to become Ready after the static Pod restarts.

<details>
<summary>Reference Answer Commands</summary>

```bash
vi /etc/kubernetes/manifests/kube-apiserver.yaml
# Set:
# --audit-policy-file=/etc/kubernetes/pki/ops-audit-rules.yaml
# --audit-log-path=/var/log/kubernetes-logs.log
# --audit-log-maxage=5
# --audit-log-maxbackup=10
# --audit-log-maxsize=100
vi /etc/kubernetes/pki/ops-audit-rules.yaml
# Preserve the existing probe exclusions, then add:
# - level: RequestResponse for batch/cronjobs
# - level: Request or RequestResponse for apps/deployments in kube-system
# - level: None for system:kube-proxy watch on core services/endpoints
# - a broader Request rule covering the remaining core and extensions resources
watch crictl ps
kubectl --kubeconfig=/etc/kubernetes/admin.conf get --raw /readyz
crictl inspect $(crictl ps --name kube-apiserver -q | head -n1) | grep audit
```

</details>

