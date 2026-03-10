This scenario rewrites a KubeSec manifest hardening task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- The Pod manifest to scan is staged at `/root/kubesec-audit.yaml`.
- The default playground uses containerd, not Docker.

Adaptation notes

- The original task says to use the KubeSec Docker image. In this scenario, the same official image `docker.io/kubesec/kubesec:v2` is invoked through a helper script backed by containerd.
- The helper script is available at `/usr/local/bin/kubesec-docker-scan`.
- Your goal is to edit `/root/kubesec-audit.yaml` until the KubeSec score is at least `4`.

Success criteria

- The manifest is scanned with the official KubeSec image through the provided helper.
- The manifest is updated with the recommended security improvements.
- The final KubeSec score is at least `4`.
