#!/bin/bash
set -euo pipefail

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
KUBECONFIG="/etc/kubernetes/admin.conf"

wait_api() {
  for _ in $(seq 1 90); do
    if kubectl --kubeconfig="${KUBECONFIG}" get --raw /readyz >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  return 1
}

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

until ssh ${SSH_OPTS} node01 true >/dev/null 2>&1; do
  sleep 1
done

ssh ${SSH_OPTS} node01 "bash -s" <<'EOF'
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
mkdir -p /home/anomalous /etc/falco /etc/falco/config.d /var/log/falco
rm -f /home/anomalous/report /var/log/falco/falco-json.log

if ! command -v falco >/dev/null 2>&1; then
  arch="$(uname -m)"
  case "${arch}" in
    x86_64|amd64)
      falco_arch="x86_64"
      ;;
    aarch64|arm64)
      falco_arch="aarch64"
      ;;
    *)
      echo "Unsupported architecture for Falco: ${arch}" >&2
      exit 1
      ;;
  esac

  workdir="$(mktemp -d)"
  trap 'rm -rf "${workdir}"' EXIT
  archive="${workdir}/falco.tar.gz"
  url="https://download.falco.org/packages/bin/${falco_arch}/falco-0.43.0-static-${falco_arch}.tar.gz"
  curl -fsSL "${url}" -o "${archive}"
  tar -xzf "${archive}" -C "${workdir}"
  set -- "${workdir}"/*
  cp -R "$1"/* /
fi

cat >/etc/falco/config.d/zz-json-output.yaml <<'EOF_CFG'
json_output: true
stdout_output:
  enabled: false
syslog_output:
  enabled: false
file_output:
  enabled: true
  keep_alive: true
  filename: /var/log/falco/falco-json.log
EOF_CFG

cat >/etc/systemd/system/falco.service <<'EOF_SERVICE'
[Unit]
Description=Falco Runtime Security
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/falco -o engine.kind=modern_ebpf -c /etc/falco/falco.yaml -r /etc/falco/falco_rules.local.yaml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF_SERVICE

cat >/etc/falco/falco_rules.local.yaml <<'EOF_RULE'
# Add your custom Falco rule here.
EOF_RULE

cat >/usr/local/bin/falco-report-bracket <<'EOF_HELPER'
#!/bin/bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: falco-report-bracket <duration-seconds> <output-file>" >&2
  exit 1
fi

duration="$1"
output_file="$2"
log_file="/var/log/falco/falco-json.log"

mkdir -p "$(dirname "${output_file}")"
: >"${log_file}"
systemctl restart falco.service
sleep 3
sleep "${duration}"

python3 - <<'PY' "${log_file}" >"${output_file}"
import json
import sys

path = sys.argv[1]
with open(path, 'r', encoding='utf-8', errors='ignore') as fh:
    for line in fh:
        line = line.strip()
        if not line or not line.startswith('{'):
            continue
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        fields = event.get('output_fields', {})
        ts = fields.get('evt.time')
        uid = fields.get('user.uid') or fields.get('user.name')
        proc = fields.get('proc.name')
        pod = fields.get('k8s.pod.name')
        if ts and uid is not None and proc and pod == 'tomcat':
            print(f"[{ts}],[{uid}],[{proc}]")
PY
EOF_HELPER

chmod 0755 /usr/local/bin/falco-report-bracket
systemctl daemon-reload
systemctl enable falco.service >/dev/null 2>&1 || true
systemctl restart falco.service >/dev/null 2>&1 || true
EOF

kubectl delete pod tomcat --ignore-not-found >/dev/null 2>&1 || true

cat <<'EOF' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Pod
metadata:
  name: tomcat
  namespace: default
spec:
  nodeName: node01
  containers:
  - name: tomcat
    image: busybox:1.36
    command:
    - sh
    - -c
    - |
      while true; do
        sh -c 'id >/dev/null'
        sleep 3
        sh -c 'uname >/dev/null'
        sleep 3
        sh -c 'date >/dev/null'
        sleep 3
      done
EOF

kubectl wait --for=condition=Ready pod/tomcat -n default --timeout=180s >/dev/null

wait_api || {
  echo "API server did not become ready" >&2
  exit 1
}
