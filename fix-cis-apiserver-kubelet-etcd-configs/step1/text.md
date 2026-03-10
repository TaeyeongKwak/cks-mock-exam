Fix the staged CIS Benchmark findings by updating the configuration files and restarting affected components.

Violations to fix

- API Server
  - `authorization-mode` must not be `AlwaysAllow`
  - It must include `Node`
  - It must include `RBAC`
- Kubelet
  - Anonymous authentication must be disabled
  - Authorization mode must use `Webhook`
- etcd
  - `--client-cert-auth` must be enabled
  - `--auto-tls` must not be enabled
  - Valid TLS certificates must be used instead of self-signed certificates

Notes

- Edit the files directly on `controlplane`.
- Restart the kubelet after changing `/var/lib/kubelet/config.yaml`.
- Static Pod changes take effect when the manifest files are updated.
