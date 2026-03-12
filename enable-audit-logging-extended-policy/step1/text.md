A forensics review needs a richer audit policy than the one currently staged on `controlplane`.

Files

- API server manifest: `/etc/kubernetes/manifests/kube-apiserver.yaml`
- Seed policy: `/etc/kubernetes/pki/forensics-audit.yaml`

Required end state

- Audit output goes to `/var/log/kubernetes-logs.log`
- Rotation keeps 12 days, 8 backups, and 200 MB per file
- The policy keeps omitting `RequestReceived`
- The rule set must include:
  - `RequestResponse` for Namespace changes
  - `Request` for Secret changes in `kube-system`
  - `Metadata` for `pods/portforward` and `services/proxy`
  - `Request` for the remaining core and `extensions` resources
  - a trailing default `Metadata` rule for everything else

Keep the existing non-resource exclusion already present in the seed file, and let the API server come back Ready before verifying.

<details>
<summary>Reference Answer Commands</summary>

```bash
vi /etc/kubernetes/manifests/kube-apiserver.yaml
# Ensure these flags exist on kube-apiserver:
# --audit-policy-file=/etc/kubernetes/pki/forensics-audit.yaml
# --audit-log-path=/var/log/kubernetes-logs.log
# --audit-log-maxage=12
# --audit-log-maxbackup=8
# --audit-log-maxsize=200

cat <<'EOF' >/etc/kubernetes/pki/forensics-audit.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
omitStages:
- RequestReceived
rules:
- level: None
  nonResourceURLs:
  - /healthz*
- level: RequestResponse
  resources:
  - group: ""
    resources:
    - namespaces
- level: Request
  namespaces:
  - kube-system
  resources:
  - group: ""
    resources:
    - secrets
- level: Metadata
  resources:
  - group: ""
    resources:
    - pods/portforward
    - services/proxy
- level: Request
  resources:
  - group: ""
    resources:
    - "*"
  - group: "extensions"
    resources:
    - "*"
- level: Metadata
EOF

# Wait for the static Pod to restart and become healthy again
watch crictl ps
kubectl --kubeconfig=/etc/kubernetes/admin.conf get --raw /readyz

# Optional checks
grep audit-log /etc/kubernetes/manifests/kube-apiserver.yaml
crictl inspect "$(crictl ps --name kube-apiserver -q | head -n1)" | grep audit
```

</details>

