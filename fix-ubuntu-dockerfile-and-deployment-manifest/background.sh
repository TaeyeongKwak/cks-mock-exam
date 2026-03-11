#!/bin/bash
set -euo pipefail

MANIFEST_DIR="${SCENARIO_MANIFEST_DIR:-/home/review-manifests}"

mkdir -p "${MANIFEST_DIR}"

cat >"${MANIFEST_DIR}/Dockerfile" <<'EOF'
FROM ubuntu:20.04
RUN apt-get update && apt-get install -y nginx && useradd -u 0 -o -m nobody
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
USER root
EOF

cat >"${MANIFEST_DIR}/deployment.yaml" <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: security-review-demo
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: security-review-demo
  template:
    metadata:
      labels:
        app: security-review-demo
    spec:
      containers:
      - name: app
        image: nginx:1.25
        securityContext:
          runAsUser: 0
          runAsNonRoot: false
EOF

cat >"${MANIFEST_DIR}/entrypoint.sh" <<'EOF'
#!/bin/sh
nginx -g 'daemon off;'
EOF

chmod +x "${MANIFEST_DIR}/entrypoint.sh"
