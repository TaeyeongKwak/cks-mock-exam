This lab starts with a partially wired API audit setup on `controlplane`.

Environment notes

- The API server runs as a static Pod from `/etc/kubernetes/manifests/kube-apiserver.yaml`.
- A seed policy file already exists at `/etc/kubernetes/pki/ops-audit-rules.yaml`.
- The current flags and policy content are intentionally incomplete.

Adaptation notes

- The policy path is different from the earlier labs so the scenario reads as a fresh environment.
- The seed file already ignores probe endpoints. Keep that suppression while adding the required resource rules.

Success criteria

- The running API server writes to `/var/log/kubernetes-logs.log`.
- Rotation is set to 5 days, 10 retained files, and 100 MB.
- CronJob changes are logged at `RequestResponse`.
- Deployment changes in `kube-system` include request bodies.
- Remaining core and `extensions` resources are captured at `Request`.
- `system:kube-proxy` `watch` calls for `endpoints` or `services` are skipped.
