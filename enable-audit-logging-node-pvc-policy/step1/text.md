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
vi /etc/kubernetes/manifests/kube-apiserver.yaml
# Ensure kube-apiserver includes these flags:
# --audit-policy-file=/etc/kubernetes/pki/audit-policy.yaml
# --audit-log-path=/var/log/kubernetes-logs.log
# --audit-log-maxage=5
# --audit-log-maxbackup=10

cat <<'EOF' >/etc/kubernetes/pki/audit-policy.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
omitStages:
- RequestReceived
rules:
- level: None
  users:
  - system:kube-proxy
  verbs:
  - watch
  resources:
  - group: ""
    resources:
    - endpoints
    - services
- level: RequestResponse
  resources:
  - group: ""
    resources:
    - nodes
- level: Request
  namespaces:
  - portal
  resources:
  - group: ""
    resources:
    - persistentvolumeclaims
EOF

# Wait for kube-apiserver to restart after the manifest change
watch crictl ps
kubectl --kubeconfig=/etc/kubernetes/admin.conf get --raw /readyz

# Optional checks
grep audit-log /etc/kubernetes/manifests/kube-apiserver.yaml
crictl inspect "$(crictl ps --name kube-apiserver -q | head -n1)" | grep audit
grep -n 'nodes\|persistentvolumeclaims\|system:kube-proxy' /etc/kubernetes/pki/audit-policy.yaml
```

</details>

