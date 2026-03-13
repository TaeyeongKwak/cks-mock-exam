#!/bin/bash
set -euo pipefail

WORKDIR="/candidate/14"
BIN="${WORKDIR}/ldap-watch"
PIDFILE="${WORKDIR}/ldap.pid"
SOURCE_C="${WORKDIR}/ldap-watch.c"

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

export DEBIAN_FRONTEND=noninteractive
apt-get update -y >/dev/null
apt-get install -y lsof gcc >/dev/null

if [ -w /etc/services ]; then
  perl -0pi -e 's/^ldap\s+389\/tcp/# ldap 389\/tcp/gm' /etc/services
fi

mkdir -p "${WORKDIR}"
rm -f "${WORKDIR}/files.txt"
rm -f "${WORKDIR}/service.log"
rm -f "${WORKDIR}/httpd"
rm -f "${SOURCE_C}"

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

cat > "${SOURCE_C}" <<'EOF'
#include <arpa/inet.h>
#include <errno.h>
#include <netinet/in.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>

static int listen_fd = -1;

static void handle_signal(int sig) {
  (void)sig;
  if (listen_fd >= 0) {
    close(listen_fd);
  }
  _exit(0);
}

int main(void) {
  struct sockaddr_in6 addr;
  int opt = 1;

  signal(SIGTERM, handle_signal);
  signal(SIGINT, handle_signal);

  listen_fd = socket(AF_INET6, SOCK_STREAM, 0);
  if (listen_fd < 0) {
    perror("socket");
    return 1;
  }

  if (setsockopt(listen_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt)) < 0) {
    perror("setsockopt");
    return 1;
  }

#ifdef IPV6_V6ONLY
  opt = 0;
  setsockopt(listen_fd, IPPROTO_IPV6, IPV6_V6ONLY, &opt, sizeof(opt));
#endif

  memset(&addr, 0, sizeof(addr));
  addr.sin6_family = AF_INET6;
  addr.sin6_addr = in6addr_any;
  addr.sin6_port = htons(389);

  if (bind(listen_fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
    perror("bind");
    return 1;
  }

  if (listen(listen_fd, 16) < 0) {
    perror("listen");
    return 1;
  }

  while (1) {
    int client_fd = accept(listen_fd, NULL, NULL);
    if (client_fd >= 0) {
      close(client_fd);
      continue;
    }

    if (errno == EINTR) {
      continue;
    }

    sleep(1);
  }
}
EOF

gcc -O2 -o "${BIN}" "${SOURCE_C}"
chmod +x "${BIN}"

nohup "${BIN}" >/candidate/14/service.log 2>&1 &
echo $! > "${PIDFILE}"

for _ in $(seq 1 30); do
  if ss -ltnp '( sport = :389 )' 2>/dev/null | grep -q '389'; then
    exit 0
  fi
  sleep 1
done

echo "Service on port 389 did not start" >&2
exit 1
