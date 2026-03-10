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
