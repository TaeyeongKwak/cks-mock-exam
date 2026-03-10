#!/bin/bash
set -euo pipefail

IMAGE="docker.io/kubesec/kubesec:v2"
HELPER="/usr/local/bin/kubesec-docker-scan"

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

cat >/root/kubesec-audit.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: kubesec-audit
spec:
  automountServiceAccountToken: true
  containers:
  - name: kubesec-audit
    image: nginx:1.25
    securityContext:
      allowPrivilegeEscalation: true
      runAsUser: 0
      capabilities:
        add: ["NET_ADMIN"]
EOF

cat >"${HELPER}" <<'EOF'
#!/bin/bash
set -euo pipefail

IMAGE="docker.io/kubesec/kubesec:v2"
FILE="${1:-}"

if [ -z "${FILE}" ]; then
  echo "usage: kubesec-docker-scan <manifest-file>" >&2
  exit 1
fi

if [ ! -f "${FILE}" ]; then
  echo "file not found: ${FILE}" >&2
  exit 1
fi

if ! ctr -n k8s.io images list | grep -q "${IMAGE}"; then
  ctr -n k8s.io images pull "${IMAGE}" >/dev/null
fi

workdir="$(cd "$(dirname "${FILE}")" && pwd)"
filename="$(basename "${FILE}")"
task="kubesec-$(date +%s)-$$"

ctr -n k8s.io run --rm \
  --mount "type=bind,src=${workdir},dst=/work,options=rbind:ro" \
  "${IMAGE}" "${task}" \
  scan "/work/${filename}"
EOF

chmod +x "${HELPER}"

# Warm the image cache so the first user scan is faster.
"${HELPER}" /root/kubesec-audit.yaml >/dev/null 2>&1 || true
