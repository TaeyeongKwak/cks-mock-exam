This lab stages a separate audit-repair exercise on `controlplane`.

Environment notes

- The API server manifest is still `/etc/kubernetes/manifests/kube-apiserver.yaml`.
- A seed policy file is placed at `/etc/kubernetes/pki/forensics-audit.yaml`.
- The current manifest points to that file, but the values are not production-ready yet.

Success criteria

- The running API server writes to `/var/log/kubernetes-logs.log`.
- Rotation is 12 days, 8 backups, and 200 MB.
- The policy omits `RequestReceived`.
- Namespace changes are logged at `RequestResponse`.
- `kube-system` Secret changes log request bodies.
- `pods/portforward` and `services/proxy` are kept at `Metadata`.
- Other core and `extensions` resources log at `Request`.
- A final default rule logs everything else at `Metadata`.
