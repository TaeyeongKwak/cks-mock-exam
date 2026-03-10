#!/bin/bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

kubectl get namespace testing-lab >/dev/null 2>&1 || fail "Namespace testing-lab not found"

kubectl get secret bingo-tls -n testing-lab >/dev/null 2>&1 || fail "Secret bingo-tls not found in testing-lab"
secret_type="$(kubectl get secret bingo-tls -n testing-lab -o jsonpath='{.type}')"
[ "${secret_type}" = "kubernetes.io/tls" ] || fail "Secret bingo-tls must be of type kubernetes.io/tls"

tls_crt="$(kubectl get secret bingo-tls -n testing-lab -o jsonpath='{.data.tls\.crt}')"
tls_key="$(kubectl get secret bingo-tls -n testing-lab -o jsonpath='{.data.tls\.key}')"
[ -n "${tls_crt}" ] || fail "Secret bingo-tls must contain tls.crt"
[ -n "${tls_key}" ] || fail "Secret bingo-tls must contain tls.key"

kubectl get pod web-pod -n testing-lab >/dev/null 2>&1 || fail "Pod web-pod not found in testing-lab"
kubectl wait --for=condition=Ready pod/web-pod -n testing-lab --timeout=180s >/dev/null 2>&1 || fail "Pod web-pod is not Ready"

pod_image="$(kubectl get pod web-pod -n testing-lab -o jsonpath='{.spec.containers[0].image}')"
echo "${pod_image}" | grep -Eqi 'nginx|httpd' || fail "Pod web-pod must use a web server image"

pod_ip="$(kubectl get pod web-pod -n testing-lab -o jsonpath='{.status.podIP}')"
[ -n "${pod_ip}" ] || fail "Could not determine Pod IP for web-pod"

service_name="$(
  kubectl get service -n testing-lab -o json | python3 - <<'PY'
import json
import sys

data = json.load(sys.stdin)
for item in data.get("items", []):
    if item["metadata"]["name"] == "kubernetes":
        continue
    if item.get("spec", {}).get("selector"):
        print(item["metadata"]["name"])
PY
)"
[ -n "${service_name}" ] || fail "No candidate Service found in testing-lab"

matched_service=""
for candidate in ${service_name}; do
  if kubectl get endpoints "${candidate}" -n testing-lab -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null | grep -qw "${pod_ip}"; then
    matched_service="${candidate}"
    break
  fi
done
[ -n "${matched_service}" ] || fail "No Service in testing-lab routes to Pod web-pod"
service_name="${matched_service}"

service_port="$(kubectl get service "${service_name}" -n testing-lab -o jsonpath='{.spec.ports[0].port}')"
[ -n "${service_port}" ] || fail "Service ${service_name} must expose a port"

ingress_name="$(
  kubectl get ingress -n testing-lab -o json | python3 - <<'PY'
import json
import sys

data = json.load(sys.stdin)
for item in data.get("items", []):
    rules = item.get("spec", {}).get("rules", [])
    tls = item.get("spec", {}).get("tls", [])
    for rule in rules:
        if rule.get("host") == "bingo.com":
            for t in tls:
                if t.get("secretName") == "bingo-tls" and "bingo.com" in t.get("hosts", []):
                    print(item["metadata"]["name"])
                    raise SystemExit
PY
)"
[ -n "${ingress_name}" ] || fail "No Ingress in testing-lab uses host bingo.com with Secret bingo-tls"

backend_service="$(
  kubectl get ingress "${ingress_name}" -n testing-lab -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}'
)"
[ "${backend_service}" = "${service_name}" ] || fail "Ingress ${ingress_name} must route to Service ${service_name}"

redirect_annotation="$(kubectl get ingress "${ingress_name}" -n testing-lab -o jsonpath='{.metadata.annotations.nginx\.ingress\.kubernetes\.io/ssl-redirect}' 2>/dev/null || true)"
[ "${redirect_annotation}" = "true" ] || fail "Ingress ${ingress_name} must set nginx.ingress.kubernetes.io/ssl-redirect=true"

path_type="$(kubectl get ingress "${ingress_name}" -n testing-lab -o jsonpath='{.spec.rules[0].http.paths[0].pathType}')"
[ -n "${path_type}" ] || fail "Ingress ${ingress_name} must define a pathType"

echo "Verification passed"
