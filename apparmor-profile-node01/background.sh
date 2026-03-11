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

cat >/root/web-guard-pod.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: web-guard
spec:
  containers:
  - name: web
    image: registry.k8s.io/e2e-test-images/agnhost:2.45
    args: ["netexec", "--http-port=8080"]
EOF

ssh ${SSH_OPTS} node01 "tee /root/web-guard.apparmor >/dev/null" <<'EOF'
#include <tunables/global>

profile web-guard flags=(attach_disconnected,mediate_deleted) {
  #include <abstractions/base>

  file,
  network,
  capability,
  mount,
  umount,
  signal,
  ptrace,
  unix,
}
EOF

kubectl delete pod web-guard --ignore-not-found >/dev/null 2>&1 || true
ssh ${SSH_OPTS} node01 "apparmor_parser -R /root/web-guard.apparmor >/dev/null 2>&1 || true"
