#!/bin/bash
set -euo pipefail

MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"
CONFDIR="/etc/kubernetes/policyconfig"
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

wait_api || fail "API server is not ready"

[ -f "${CONFDIR}/admission-config.yaml" ] || fail "Admission config not found in /etc/kubernetes/policyconfig"
[ -f "${CONFDIR}/imagepolicyconfig.yaml" ] || fail "ImagePolicyWebhook config not found in /etc/kubernetes/policyconfig"
[ -f "${CONFDIR}/webhook.kubeconfig" ] || fail "Webhook kubeconfig not found in /etc/kubernetes/policyconfig"
[ -f "/root/17/insecure-image.yaml" ] || fail "Test manifest not found at /root/17/insecure-image.yaml"

grep -q -- '--admission-control-config-file=/etc/kubernetes/policyconfig/admission-config.yaml' "${MANIFEST}" || fail "kube-apiserver must use /etc/kubernetes/policyconfig/admission-config.yaml"
runtime_line="$(grep -- '--runtime-config=' "${MANIFEST}" || true)"
echo "${runtime_line}" | grep -q 'imagepolicy.k8s.io/v1alpha1=true' || fail "kube-apiserver must enable imagepolicy.k8s.io/v1alpha1 runtime config"

enable_line="$(grep -- '--enable-admission-plugins=' "${MANIFEST}" || true)"
echo "${enable_line}" | grep -q 'ImagePolicyWebhook' || fail "ImagePolicyWebhook must be enabled in --enable-admission-plugins"

grep -q 'defaultAllow: false' "${CONFDIR}/imagepolicyconfig.yaml" || fail "Image policy must enforce implicit deny with defaultAllow: false"
grep -q '/etc/kubernetes/policyconfig/webhook.kubeconfig' "${CONFDIR}/imagepolicyconfig.yaml" || fail "Image policy config must reference the staged webhook kubeconfig"
grep -q 'server: https://valhalla.local:8081/image_policy' "${CONFDIR}/webhook.kubeconfig" || fail "Webhook kubeconfig must use https://valhalla.local:8081/image_policy"
grep -q 'ImagePolicyWebhook' "${CONFDIR}/admission-config.yaml" || fail "AdmissionConfiguration must include the ImagePolicyWebhook plugin"
grep -q '/etc/kubernetes/policyconfig/imagepolicyconfig.yaml' "${CONFDIR}/admission-config.yaml" || fail "AdmissionConfiguration must point to imagepolicyconfig.yaml"

apiserver_id="$(crictl ps --name kube-apiserver -q | head -n 1 | tr -d '\r')"
[ -n "${apiserver_id}" ] || fail "Running kube-apiserver container not found"
apiserver_inspect="$(crictl inspect "${apiserver_id}" 2>/dev/null || true)"
echo "${apiserver_inspect}" | grep -q -- '--admission-control-config-file=/etc/kubernetes/policyconfig/admission-config.yaml' || fail "Running kube-apiserver is not using the required admission config"
echo "${apiserver_inspect}" | grep -q 'imagepolicy.k8s.io/v1alpha1=true' || fail "Running kube-apiserver is not enabling imagepolicy.k8s.io/v1alpha1"
echo "${apiserver_inspect}" | grep -q 'ImagePolicyWebhook' || fail "Running kube-apiserver does not enable ImagePolicyWebhook"

systemctl is-active image-policy-webhook.service >/dev/null 2>&1 || fail "image-policy-webhook.service is not active"

apply_output="$(kubectl apply -f /root/17/insecure-image.yaml 2>&1 || true)"
echo "${apply_output}" | grep -Eqi 'denied|forbidden|rejected|latest or unpinned image tags are rejected|image is not explicitly allowlisted' || fail "Applying /root/17/insecure-image.yaml was not denied by the image policy webhook"

if kubectl get pod insecure-nginx -n default >/dev/null 2>&1; then
  fail "Pod insecure-nginx should not have been created"
fi

echo "Verification passed"
