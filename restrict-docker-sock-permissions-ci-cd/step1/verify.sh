#!/bin/bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get namespace ci-sec >/dev/null 2>&1 || fail "Namespace ci-sec not found"
kubectl get deployment build-runner -n ci-sec >/dev/null 2>&1 || fail "Deployment build-runner not found"
kubectl rollout status deployment/build-runner -n ci-sec --timeout=120s >/dev/null 2>&1 || fail "Deployment build-runner is not ready"

runner_mount="$(kubectl get deployment build-runner -n ci-sec -o jsonpath='{range .spec.template.spec.containers[?(@.name=="builder")].volumeMounts[*]}{.mountPath}{"\n"}{end}' 2>/dev/null || true)"
echo "${runner_mount}" | grep -qx '/var/run/docker.sock' || fail "builder container must still mount /var/run/docker.sock"

pod_name="$(kubectl get pods -n ci-sec -l app=build-runner -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)"
[ -n "${pod_name}" ] || fail "No running Pod found for deployment build-runner"
kubectl wait --for=condition=Ready "pod/${pod_name}" -n ci-sec --timeout=120s >/dev/null 2>&1 || fail "Pod ${pod_name} is not Ready"

stat_output="$(kubectl exec -n ci-sec -c builder "${pod_name}" -- sh -c "stat -c '%u:%g %a' /var/run/docker.sock" 2>/dev/null || true)"
[ "${stat_output}" = "1000:1000 600" ] || fail "builder sees /var/run/docker.sock as '${stat_output}', expected '1000:1000 600'"

runner_access="$(kubectl exec -n ci-sec -c builder "${pod_name}" -- sh -c 'if [ -r /var/run/docker.sock ] && [ -w /var/run/docker.sock ]; then echo allowed; else echo blocked; fi' 2>/dev/null || true)"
[ "${runner_access}" = "allowed" ] || fail "builder container must retain access to /var/run/docker.sock"

auditor_access="$(kubectl exec -n ci-sec -c observer "${pod_name}" -- sh -c 'if [ -r /var/run/docker.sock ] || [ -w /var/run/docker.sock ]; then echo allowed; else echo blocked; fi' 2>/dev/null || true)"
[ "${auditor_access}" = "blocked" ] || fail "observer container can still access /var/run/docker.sock"

echo "Verification passed"
