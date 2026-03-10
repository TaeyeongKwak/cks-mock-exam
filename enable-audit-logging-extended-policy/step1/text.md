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
