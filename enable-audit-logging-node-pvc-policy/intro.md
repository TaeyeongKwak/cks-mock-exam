This scenario focuses on tuning Kubernetes audit logging in the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- The kube-apiserver runs as a static Pod.
- The API server manifest is `/etc/kubernetes/manifests/kube-apiserver.yaml`.
- Namespace `portal` already exists.

Success criteria

- Audit logs are written to `/var/log/kubernetes-logs.log`.
- Log retention is 5 days and 10 old files.
- The base exclusion policy remains in place.
- Node changes are logged at `RequestResponse`.
- PersistentVolumeClaim changes in namespace `portal` are logged with the request body.
