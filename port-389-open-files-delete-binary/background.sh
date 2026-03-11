#!/bin/bash
set -euo pipefail

WORKDIR="/candidate/14"
BIN="${WORKDIR}/ldap-watch"
PIDFILE="${WORKDIR}/ldap.pid"

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

export DEBIAN_FRONTEND=noninteractive
apt-get update -y >/dev/null
apt-get install -y lsof >/dev/null

mkdir -p "${WORKDIR}"
rm -f "${WORKDIR}/files.txt"

if [ -f "${PIDFILE}" ]; then
  old_pid="$(cat "${PIDFILE}" 2>/dev/null || true)"
  if [ -n "${old_pid}" ] && kill -0 "${old_pid}" 2>/dev/null; then
    kill "${old_pid}" >/dev/null 2>&1 || true
    sleep 1
  fi
fi

pid_on_389="$(ss -ltnp '( sport = :389 )' 2>/dev/null | awk -F'pid=' 'NR>1 && NF>1 {split($2,a,","); print a[1]; exit}')"
if [ -n "${pid_on_389}" ]; then
  kill "${pid_on_389}" >/dev/null 2>&1 || true
  sleep 1
fi

cp /bin/busybox "${BIN}"
chmod +x "${BIN}"

nohup "${BIN}" httpd -f -p 389 >/candidate/14/service.log 2>&1 &
echo $! > "${PIDFILE}"

for _ in $(seq 1 30); do
  if ss -ltnp '( sport = :389 )' 2>/dev/null | grep -q '389'; then
    exit 0
  fi
  sleep 1
done

echo "Service on port 389 did not start" >&2
exit 1
