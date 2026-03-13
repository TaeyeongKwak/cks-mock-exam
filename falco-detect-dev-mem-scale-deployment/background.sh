#!/bin/bash
set -euo pipefail

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

LAB_DIR="/opt/falco-lab"
mkdir -p "${LAB_DIR}"

kubectl delete deployment mem-hacker -n default --ignore-not-found >/dev/null 2>&1 || true
kubectl apply -f - <<'EOF' >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mem-hacker
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mem-hacker
  template:
    metadata:
      labels:
        app: mem-hacker
    spec:
      containers:
      - name: hacker
        image: busybox:1.36
        command:
        - /bin/sh
        - -c
        - |
          while true; do
            cat /dev/mem >/dev/null 2>&1 || true
            sleep 2
          done
EOF

kubectl rollout status deployment/mem-hacker -n default --timeout=180s >/dev/null
POD_NAME="$(kubectl get pod -n default -l app=mem-hacker -o jsonpath='{.items[0].metadata.name}')"

cat > "${LAB_DIR}/falco-events.log" <<EOF
$(date +%H:%M:%S).000000: Warning Process cat accessed /dev/mem (command=cat /dev/mem user=root container=simulated-container image=busybox pod_name=${POD_NAME} namespace=default)
EOF

if ! command -v falco >/dev/null 2>&1; then
  cat > /usr/local/bin/falco <<'EOF'
#!/bin/bash
set -euo pipefail

RULE_FILE=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -r)
      RULE_FILE="${2:-}"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

if [ -z "${RULE_FILE}" ] || [ ! -f "${RULE_FILE}" ]; then
  echo "falco: rule file not found" >&2
  exit 1
fi

if ! grep -Eq 'fd\.name[[:space:]]+contains[[:space:]]+/dev/mem' "${RULE_FILE}"; then
  echo "falco: no /dev/mem rule matched in ${RULE_FILE}" >&2
  exit 2
fi

cat /opt/falco-lab/falco-events.log
EOF
  chmod +x /usr/local/bin/falco
fi

rm -f /root/rule.yaml