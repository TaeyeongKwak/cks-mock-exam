#!/bin/bash
set -euo pipefail

MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"
CONFDIR="/etc/kubernetes/confcontrol"
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

[ -f "${CONFDIR}/admission-config.yaml" ] || fail "Admission config not found in /etc/kubernetes/confcontrol"
[ -f "${CONFDIR}/imagepolicyconfig.yaml" ] || fail "ImagePolicyWebhook config not found in /etc/kubernetes/confcontrol"
[ -f "/root/latest-deny-pod.yaml" ] || fail "Test Pod manifest not found at /root/latest-deny-pod.yaml"

grep -q -- '--admission-control-config-file=/etc/kubernetes/confcontrol/admission-config.yaml' "${MANIFEST}" || fail "kube-apiserver must use /etc/kubernetes/confcontrol/admission-config.yaml"
runtime_line="$(grep -- '--runtime-config=' "${MANIFEST}" || true)"
echo "${runtime_line}" | grep -q 'imagepolicy.k8s.io/v1alpha1=true' || fail "kube-apiserver must enable imagepolicy.k8s.io/v1alpha1 runtime config"

enable_line="$(grep -- '--enable-admission-plugins=' "${MANIFEST}" || true)"
echo "${enable_line}" | grep -q 'ImagePolicyWebhook' || fail "ImagePolicyWebhook must be enabled in --enable-admission-plugins"

apiserver_id="$(crictl ps --name kube-apiserver -q | head -n 1 | tr -d '\r')"
[ -n "${apiserver_id}" ] || fail "Running kube-apiserver container not found"
apiserver_inspect="$(crictl inspect "${apiserver_id}" 2>/dev/null || true)"
echo "${apiserver_inspect}" | grep -q -- '--admission-control-config-file=/etc/kubernetes/confcontrol/admission-config.yaml' || fail "Running kube-apiserver is not using the required admission config"
echo "${apiserver_inspect}" | grep -q 'imagepolicy.k8s.io/v1alpha1=true' || fail "Running kube-apiserver is not enabling imagepolicy.k8s.io/v1alpha1"
echo "${apiserver_inspect}" | grep -q 'ImagePolicyWebhook' || fail "Running kube-apiserver does not enable ImagePolicyWebhook"

grep -q 'defaultAllow: false' "${CONFDIR}/imagepolicyconfig.yaml" || fail "Image policy must use implicit deny via defaultAllow: false"
grep -q '/etc/kubernetes/confcontrol/webhook.kubeconfig' "${CONFDIR}/imagepolicyconfig.yaml" || fail "Image policy config must reference the staged webhook kubeconfig"

grep -q 'ImagePolicyWebhook' "${CONFDIR}/admission-config.yaml" || fail "AdmissionConfiguration must include the ImagePolicyWebhook plugin"
grep -q '/etc/kubernetes/confcontrol/imagepolicyconfig.yaml' "${CONFDIR}/admission-config.yaml" || fail "AdmissionConfiguration must point to imagepolicyconfig.yaml"

apply_output="$(kubectl apply -f /root/latest-deny-pod.yaml 2>&1 || true)"
echo "${apply_output}" | grep -Eqi 'denied|forbidden|latest image tags are not allowed' || fail "Applying the latest-tag test Pod was not denied by the image policy webhook"

if kubectl get pod latest-deny >/dev/null 2>&1; then
  fail "Pod latest-deny should not have been created"
fi

systemctl is-active image-policy-webhook.service >/dev/null 2>&1 || fail "image-policy-webhook.service is not active"

echo "Verification passed"
