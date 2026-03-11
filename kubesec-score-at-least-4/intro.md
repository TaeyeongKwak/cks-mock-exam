This scenario rewrites a KubeSec manifest hardening task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- The Pod manifest to scan is staged at `/root/kubesec-audit.yaml`.
- The default playground uses containerd, not Docker.

Success criteria

- The manifest is scanned with the official KubeSec image through the provided helper.
- The manifest is updated with the recommended security improvements.
- The final KubeSec score is at least `4`.
