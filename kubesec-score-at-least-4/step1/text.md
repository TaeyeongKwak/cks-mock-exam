Use KubeSec to scan the staged Pod manifest and improve its score.

Files and tools

- Manifest: `/root/kubesec-audit.yaml`
- Helper to run the official KubeSec image: `/usr/local/bin/kubesec-docker-scan`

Requirements

- Scan `/root/kubesec-audit.yaml` with KubeSec.
- Apply the recommended security fixes to the manifest.
- Reach a KubeSec score of at least `4`.

Notes

- The helper script runs the official image `docker.io/kubesec/kubesec:v2` through containerd.
- You only need to edit the staged manifest file.
