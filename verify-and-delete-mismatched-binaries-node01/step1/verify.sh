#!/bin/bash
set -euo pipefail

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
TARGET_DIR="/opt/candidate/15a/binaries"

fail() {
  echo "$1" >&2
  exit 1
}

for binary in kube-apiserver kube-controller-manager kube-proxy kubelet; do
  if ssh ${SSH_OPTS} node01 "test -e ${TARGET_DIR}/${binary}"; then
    fail "Mismatched binary still exists on node01: ${TARGET_DIR}/${binary}"
  fi
done

if ! ssh ${SSH_OPTS} node01 "test -f /opt/candidate/15a/verified-sha512.txt"; then
  fail "Expected checksum file is missing on node01"
fi

echo "Verification passed"
