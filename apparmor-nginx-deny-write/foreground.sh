#!/bin/bash
set -euo pipefail

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

until ssh ${SSH_OPTS} node01 true >/dev/null 2>&1; do
  sleep 1
done

if ! ssh ${SSH_OPTS} node01 "test -f /sys/module/apparmor/parameters/enabled && grep -qx 'Y' /sys/module/apparmor/parameters/enabled"; then
  echo "AppArmor is not enabled on node01" >&2
  exit 1
fi

cat >/root/cache-probe.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: cache-probe
spec:
  containers:
  - name: probe
    image: busybox:1.36
    command:
    - sh
    - -c
    - |
      mkdir -p /var/cache/demo
      sleep 3600
EOF

ssh ${SSH_OPTS} node01 "tee /root/cache-lockdown.apparmor >/dev/null" <<'EOF'
#include <tunables/global>

profile cache-lockdown flags=(attach_disconnected,mediate_deleted) {
  #include <abstractions/base>

  file,
  network,
  capability,
  signal,
  ptrace,
  unix,

  deny /var/cache/demo/** w,
}
EOF

kubectl delete pod cache-probe --ignore-not-found >/dev/null 2>&1 || true
ssh ${SSH_OPTS} node01 "apparmor_parser -R /root/cache-lockdown.apparmor >/dev/null 2>&1 || true"
