This scenario rewrites a KubeSec manifest hardening task for the default Killercoda Kubernetes playground.

Environment notes

- Start on `controlplane`.
- The target manifest is staged at `/root/kubesec-test.yaml`.
- A local helper script is staged to simulate `kubesec scan` scoring in a deterministic way for this lab.

Success criteria

- Scan `/root/kubesec-test.yaml` with the provided KubeSec-style scanner.
- Apply the recommended Pod security changes.
- Reach a score of at least `4` while keeping the manifest valid.
