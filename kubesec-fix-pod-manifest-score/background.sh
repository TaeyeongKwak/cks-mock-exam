#!/bin/bash
set -euo pipefail

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

cat >/root/kubesec-test.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: kubesec-demo
spec:
  containers:
  - name: kubesec-demo
    image: gcr.io/google-samples/node-hello:1.0
    securityContext:
      readOnlyRootFilesystem: true
      allowPrivilegeEscalation: true
      capabilities:
        add:
        - SYS_ADMIN
EOF

cat >/usr/local/bin/kubesec <<'EOF'
#!/bin/bash
set -euo pipefail

if [ "$#" -ne 2 ] || [ "$1" != "scan" ]; then
  echo "usage: kubesec scan <manifest-file>" >&2
  exit 1
fi

manifest="$2"

[ -f "${manifest}" ] || {
  echo "manifest not found: ${manifest}" >&2
  exit 1
}

kubectl create --dry-run=client -f "${manifest}" >/dev/null 2>&1 || {
  echo "manifest is not valid" >&2
  exit 1
}

score=0
critical_entries=""

has_jsonpath() {
  local expr="$1"
  local expected="$2"
  local value
  value="$(kubectl create --dry-run=client -f "${manifest}" -o jsonpath="${expr}" 2>/dev/null || true)"
  [ "${value}" = "${expected}" ]
}

if has_jsonpath '{.spec.containers[0].securityContext.runAsNonRoot}' 'true'; then
  score=$((score + 2))
else
  critical_entries+='{"selector":"containers[] .securityContext .runAsNonRoot == true","reason":"Force the running image to run as a non-root user to ensure least privilege"},'
  score=$((score - 10))
fi

if has_jsonpath '{.spec.containers[0].securityContext.runAsUser}' '1000'; then
  score=$((score + 2))
else
  critical_entries+='{"selector":"containers[] .securityContext .runAsUser != 0","reason":"Run the container as a non-root user with a fixed UID"},'
  score=$((score - 5))
fi

if has_jsonpath '{.spec.containers[0].securityContext.allowPrivilegeEscalation}' 'false'; then
  score=$((score + 2))
else
  critical_entries+='{"selector":"containers[] .securityContext .allowPrivilegeEscalation == false","reason":"Disable privilege escalation"},'
  score=$((score - 7))
fi

if has_jsonpath '{.spec.containers[0].securityContext.readOnlyRootFilesystem}' 'true'; then
  score=$((score + 1))
else
  critical_entries+='{"selector":"containers[] .securityContext .readOnlyRootFilesystem == true","reason":"Use a read-only root filesystem"},'
  score=$((score - 3))
fi

drop_all="$(kubectl create --dry-run=client -f "${manifest}" -o jsonpath='{.spec.containers[0].securityContext.capabilities.drop[*]}' 2>/dev/null || true)"
if [[ " ${drop_all} " == *" ALL "* ]]; then
  score=$((score + 2))
else
  critical_entries+='{"selector":"containers[] .securityContext .capabilities .drop == ALL","reason":"Drop all default capabilities"},'
  score=$((score - 7))
fi

add_caps="$(kubectl create --dry-run=client -f "${manifest}" -o jsonpath='{.spec.containers[0].securityContext.capabilities.add[*]}' 2>/dev/null || true)"
if [[ " ${add_caps} " == *" SYS_ADMIN "* ]]; then
  critical_entries+='{"selector":"containers[] .securityContext .capabilities .add == SYS_ADMIN","reason":"CAP_SYS_ADMIN is the most privileged capability and should always be avoided"},'
  score=$((score - 10))
fi

message="Failed with a score of ${score} points"
if [ "${score}" -ge 4 ]; then
  message="Passed with a score of ${score} points"
fi

critical_entries="[${critical_entries%,}]"

printf '[{"object":"Pod/kubesec-demo.default","valid":true,"message":"%s","score":%s,"scoring":{"critical":%s}}]\n' "${message}" "${score}" "${critical_entries}"
EOF

chmod 0755 /usr/local/bin/kubesec
