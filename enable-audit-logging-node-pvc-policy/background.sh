#!/bin/bash
set -euo pipefail

MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"
POLICY="/etc/kubernetes/pki/audit-policy.yaml"
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
kubectl create namespace portal --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cp "${MANIFEST}" /root/kube-apiserver.yaml.audit-node-pvc.bak

if grep -q -- '--audit-policy-file=' "${MANIFEST}"; then
  sed -i 's@--audit-policy-file=.*@    - --audit-policy-file=/etc/kubernetes/pki/audit-policy.yaml@' "${MANIFEST}"
else
  sed -i '/--profiling=false/a\    - --audit-policy-file=/etc/kubernetes/pki/audit-policy.yaml' "${MANIFEST}"
fi

if grep -q -- '--audit-log-path=' "${MANIFEST}"; then
  sed -i 's@--audit-log-path=.*@    - --audit-log-path=/var/log/apiserver-audit.log@' "${MANIFEST}"
else
  sed -i '/--audit-policy-file=\/etc\/kubernetes\/pki\/audit-policy.yaml/a\    - --audit-log-path=/var/log/apiserver-audit.log' "${MANIFEST}"
fi

for flag in audit-log-maxage audit-log-maxbackup audit-log-maxsize; do
  sed -i "/--${flag}=/d" "${MANIFEST}"
done

sed -i '/--audit-log-path=\/var\/log\/apiserver-audit.log/a\    - --audit-log-maxage=7\n    - --audit-log-maxbackup=3\n    - --audit-log-maxsize=20' "${MANIFEST}"

cat >"${POLICY}" <<'EOF'
apiVersion: audit.k8s.io/v1
kind: Policy
omitStages:
  - RequestReceived
rules:
  - level: None
    users: ["system:kube-proxy"]
    verbs: ["watch"]
    resources:
      - group: ""
        resources: ["endpoints", "services"]
EOF

if ! wait_api; then
  echo "kube-apiserver did not become ready after staging the audit configuration" >&2
  exit 1
fi
