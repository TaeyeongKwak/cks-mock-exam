#!/bin/bash
set -euo pipefail

MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"
POLICY="/etc/kubernetes/pki/audit-policy.yaml"
KUBECONFIG="/etc/kubernetes/admin.conf"

fail() {
  echo "$1" >&2
  exit 1
}

wait_api() {
  for _ in $(seq 1 90); do
    if kubectl --kubeconfig="${KUBECONFIG}" get --raw /readyz >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  return 1
}

find_rule_line() {
  local level="$1"
  local pat1="${2-}"
  local pat2="${3-}"
  local pat3="${4-}"
  local pat4="${5-}"
  local pat5="${6-}"

  awk -v level="${level}" -v pat1="${pat1}" -v pat2="${pat2}" -v pat3="${pat3}" -v pat4="${pat4}" -v pat5="${pat5}" '
    function contains(block, pat) {
      return pat == "" || index(block, pat) > 0
    }
    function matches(block) {
      return index(block, "level: " level) > 0 &&
             contains(block, pat1) &&
             contains(block, pat2) &&
             contains(block, pat3) &&
             contains(block, pat4) &&
             contains(block, pat5)
    }
    /^[[:space:]]*-[[:space:]]*level:/ {
      if (in_block && matches(block)) {
        print start_line
        exit 0
      }
      block = $0 "\n"
      start_line = NR
      in_block = 1
      next
    }
    {
      if (in_block) {
        block = block $0 "\n"
      }
    }
    END {
      if (in_block && matches(block)) {
        print start_line
        exit 0
      }
      exit 1
    }
  ' "${POLICY}"
}

wait_api || fail "API server is not ready"
[ -f "${POLICY}" ] || fail "Audit policy file not found at ${POLICY}"

grep -q -- '--audit-policy-file=/etc/kubernetes/pki/audit-policy.yaml' "${MANIFEST}" || fail "kube-apiserver must use --audit-policy-file=/etc/kubernetes/pki/audit-policy.yaml"
grep -q -- '--audit-log-path=/var/log/kubernetes-logs.log' "${MANIFEST}" || fail "kube-apiserver must use --audit-log-path=/var/log/kubernetes-logs.log"
grep -q -- '--audit-log-maxage=5' "${MANIFEST}" || fail "kube-apiserver must use --audit-log-maxage=5"
grep -q -- '--audit-log-maxbackup=10' "${MANIFEST}" || fail "kube-apiserver must use --audit-log-maxbackup=10"

container_id="$(crictl ps --name kube-apiserver -q | head -n 1 | tr -d '\r')"
[ -n "${container_id}" ] || fail "Running kube-apiserver container not found"

inspect_output="$(crictl inspect "${container_id}" 2>/dev/null || true)"
echo "${inspect_output}" | grep -q -- '--audit-policy-file=/etc/kubernetes/pki/audit-policy.yaml' || fail "Running kube-apiserver container is not using the audit policy file"
echo "${inspect_output}" | grep -q -- '--audit-log-path=/var/log/kubernetes-logs.log' || fail "Running kube-apiserver container is not using the required audit log path"
echo "${inspect_output}" | grep -q -- '--audit-log-maxage=5' || fail "Running kube-apiserver container is not using audit-log-maxage=5"
echo "${inspect_output}" | grep -q -- '--audit-log-maxbackup=10' || fail "Running kube-apiserver container is not using audit-log-maxbackup=10"

grep -q 'apiVersion: audit.k8s.io/v1' "${POLICY}" || fail "Audit policy must use apiVersion audit.k8s.io/v1"
grep -q 'kind: Policy' "${POLICY}" || fail "Audit policy kind must be Policy"
grep -Eq '^[[:space:]]*omitStages:' "${POLICY}" || fail "Audit policy must define omitStages"
grep -q 'RequestReceived' "${POLICY}" || fail "Audit policy must omit the RequestReceived stage"

exclude_line="$(find_rule_line "None" 'system:kube-proxy' 'watch' 'endpoints' 'services' 'group: ""' || true)"
[ -n "${exclude_line}" ] || fail "The staged exclusion rule must remain in the audit policy"

node_line="$(find_rule_line "RequestResponse" 'group: ""' 'nodes' || true)"
[ -n "${node_line}" ] || fail "Audit policy must log Node changes at RequestResponse"

pvc_line="$(find_rule_line "Request" 'group: ""' 'persistentvolumeclaims' 'portal' || true)"
if [ -z "${pvc_line}" ]; then
  pvc_line="$(find_rule_line "RequestResponse" 'group: ""' 'persistentvolumeclaims' 'portal' || true)"
fi
[ -n "${pvc_line}" ] || fail "Audit policy must log portal PersistentVolumeClaim changes with the request body"

kubectl --kubeconfig="${KUBECONFIG}" get namespace portal >/dev/null 2>&1 || fail "Namespace portal not found"

echo "Verification passed"
