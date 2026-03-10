#!/bin/bash
set -euo pipefail

MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"
POLICY="/etc/kubernetes/pki/ops-audit-rules.yaml"
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

upsert_flag() {
  local flag_name="$1"
  local flag_value="$2"
  if grep -q -- "--${flag_name}=" "${MANIFEST}"; then
    sed -i "s@--${flag_name}=.*@    - --${flag_name}=${flag_value}@" "${MANIFEST}"
  else
    sed -i "/--profiling=false/a\\    - --${flag_name}=${flag_value}" "${MANIFEST}"
  fi
}

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

cp "${MANIFEST}" /root/kube-apiserver.yaml.ops-audit.bak

upsert_flag "audit-policy-file" "/etc/kubernetes/pki/ops-audit-rules.yaml"
upsert_flag "audit-log-path" "/var/log/ops-audit.log"

for flag in audit-log-maxage audit-log-maxbackup audit-log-maxsize; do
  sed -i "/--${flag}=/d" "${MANIFEST}"
done

sed -i '/--audit-log-path=\/var\/log\/ops-audit.log/a\    - --audit-log-maxage=2\n    - --audit-log-maxbackup=1\n    - --audit-log-maxsize=20' "${MANIFEST}"

cat >"${POLICY}" <<'EOF'
apiVersion: audit.k8s.io/v1
kind: Policy
omitStages:
  - RequestReceived
rules:
  - level: None
    nonResourceURLs:
      - /livez*
      - /readyz*
  - level: Metadata
EOF

if ! wait_api; then
  echo "kube-apiserver did not become ready after staging the audit configuration" >&2
  exit 1
fi
