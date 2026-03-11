#!/bin/bash
set -euo pipefail

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

cat >/root/Dockerfile <<'EOF'
FROM ubuntu:latest
RUN apt-get update -y
RUN apt-get install nginx -y
COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
USER ROOT
EOF

cat >/root/pod-security-audit.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: security-audit-pod
spec:
  securityContext:
    runAsUser: 1000
  containers:
  - name: security-audit-pod
    image: gcr.io/google-samples/node-hello:1.0
    securityContext:
      runAsUser: 0
      privileged: true
      allowPrivilegeEscalation: false
EOF

cat >/root/entrypoint.sh <<'EOF'
#!/bin/sh
nginx -g 'daemon off;'
EOF

chmod +x /root/entrypoint.sh
