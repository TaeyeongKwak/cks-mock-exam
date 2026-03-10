#!/bin/bash
set -euo pipefail

MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"
CONFDIR="/etc/kubernetes/policyconfig"
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

ensure_certs() {
  mkdir -p "${CONFDIR}"

  if [ ! -f "${CONFDIR}/ca.crt" ]; then
    openssl genrsa -out "${CONFDIR}/ca.key" 2048 >/dev/null 2>&1
    openssl req -x509 -new -nodes -key "${CONFDIR}/ca.key" -subj "/CN=valhalla-imagepolicy-ca" -days 3650 -out "${CONFDIR}/ca.crt" >/dev/null 2>&1
  fi

  cat >"${CONFDIR}/server-openssl.cnf" <<'EOF'
[ req ]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[ req_distinguished_name ]
CN = valhalla.local

[ v3_req ]
subjectAltName = @alt_names
extendedKeyUsage = serverAuth

[ alt_names ]
DNS.1 = valhalla.local
DNS.2 = localhost
IP.1 = 127.0.0.1
EOF

  openssl genrsa -out "${CONFDIR}/server.key" 2048 >/dev/null 2>&1
  openssl req -new -key "${CONFDIR}/server.key" -out "${CONFDIR}/server.csr" -config "${CONFDIR}/server-openssl.cnf" >/dev/null 2>&1
  openssl x509 -req -in "${CONFDIR}/server.csr" -CA "${CONFDIR}/ca.crt" -CAkey "${CONFDIR}/ca.key" -CAcreateserial -out "${CONFDIR}/server.crt" -days 3650 -extensions v3_req -extfile "${CONFDIR}/server-openssl.cnf" >/dev/null 2>&1

  openssl genrsa -out "${CONFDIR}/client.key" 2048 >/dev/null 2>&1
  openssl req -new -key "${CONFDIR}/client.key" -subj "/CN=kube-apiserver-imagepolicy" -out "${CONFDIR}/client.csr" >/dev/null 2>&1
  openssl x509 -req -in "${CONFDIR}/client.csr" -CA "${CONFDIR}/ca.crt" -CAkey "${CONFDIR}/ca.key" -CAcreateserial -out "${CONFDIR}/client.crt" -days 3650 >/dev/null 2>&1
}

install_webhook() {
  cat >"${CONFDIR}/image-policy-server.py" <<'EOF'
#!/usr/bin/env python3
import json
import ssl
from http.server import BaseHTTPRequestHandler, HTTPServer

ALLOWED_IMAGES = {
    "registry.k8s.io/pause:3.9",
    "busybox:1.36",
    "nginx:1.25.5",
}

class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(length)
        review = json.loads(raw.decode("utf-8"))
        containers = review.get("spec", {}).get("containers", [])
        allowed = True
        reason = "allowed"

        for container in containers:
            image = container.get("image", "")
            if image.endswith(":latest") or ":" not in image:
                allowed = False
                reason = "latest or unpinned image tags are rejected"
                break
            if image not in ALLOWED_IMAGES:
                allowed = False
                reason = "image is not explicitly allowlisted"
                break

        response = {
            "apiVersion": review.get("apiVersion", "imagepolicy.k8s.io/v1alpha1"),
            "kind": "ImageReview",
            "status": {
                "allowed": allowed,
                "reason": reason
            }
        }
        body = json.dumps(response).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        return

server = HTTPServer(("0.0.0.0", 8081), Handler)
context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
context.load_cert_chain("/etc/kubernetes/policyconfig/server.crt", "/etc/kubernetes/policyconfig/server.key")
server.socket = context.wrap_socket(server.socket, server_side=True)
server.serve_forever()
EOF
  chmod +x "${CONFDIR}/image-policy-server.py"

  cat >/etc/systemd/system/image-policy-webhook.service <<'EOF'
[Unit]
Description=Local image policy webhook
After=network.target

[Service]
ExecStart=/usr/bin/python3 /etc/kubernetes/policyconfig/image-policy-server.py
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable --now image-policy-webhook.service >/dev/null
}

stage_configs() {
  cat >"${CONFDIR}/webhook.kubeconfig" <<'EOF'
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority: /etc/kubernetes/policyconfig/ca.crt
    server: https://valhalla.local:8081/image_policy
  name: imagepolicy
contexts:
- context:
    cluster: imagepolicy
    user: apiserver
  name: imagepolicy
current-context: imagepolicy
users:
- name: apiserver
  user:
    client-certificate: /etc/kubernetes/policyconfig/client.crt
    client-key: /etc/kubernetes/policyconfig/client.key
EOF

  cat >"${CONFDIR}/imagepolicyconfig.yaml" <<'EOF'
imagePolicy:
  kubeConfigFile: /etc/kubernetes/policyconfig/webhook.kubeconfig
  allowTTL: 30
  denyTTL: 30
  retryBackoff: 500
  defaultAllow: true
EOF

  cat >"${CONFDIR}/admission-config.yaml" <<'EOF'
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
  - name: ImagePolicyWebhook
    path: /etc/kubernetes/policyconfig/imagepolicyconfig.yaml
EOF
}

stage_apiserver() {
  cp "${MANIFEST}" /root/kube-apiserver.yaml.imagepolicy.valhalla.bak

  python3 - <<'PY'
from pathlib import Path
path = Path("/etc/kubernetes/manifests/kube-apiserver.yaml")
text = path.read_text()

mount_block = """    - mountPath: /etc/kubernetes/policyconfig
      name: policyconfig
      readOnly: true
"""
volume_block = """  - hostPath:
      path: /etc/kubernetes/policyconfig
      type: DirectoryOrCreate
    name: policyconfig
"""
host_alias_block = """  hostAliases:
  - ip: 127.0.0.1
    hostnames:
    - valhalla.local
"""

if "mountPath: /etc/kubernetes/policyconfig" not in text and "mountPath: /etc/kubernetes/pki" in text:
    text = text.replace(
        "    - mountPath: /etc/kubernetes/pki\n      name: k8s-certs\n      readOnly: true\n",
        "    - mountPath: /etc/kubernetes/pki\n      name: k8s-certs\n      readOnly: true\n" + mount_block
    )

if "path: /etc/kubernetes/policyconfig" not in text and "path: /etc/kubernetes/pki" in text:
    text = text.replace(
        "  - hostPath:\n      path: /etc/kubernetes/pki\n      type: DirectoryOrCreate\n    name: k8s-certs\n",
        "  - hostPath:\n      path: /etc/kubernetes/pki\n      type: DirectoryOrCreate\n    name: k8s-certs\n" + volume_block
    )

if "valhalla.local" not in text and "hostNetwork: true\n" in text:
    text = text.replace("  hostNetwork: true\n", "  hostNetwork: true\n" + host_alias_block)

path.write_text(text)
PY

  sed -i '/--admission-control-config-file=/d' "${MANIFEST}"
  sed -i '/--runtime-config=/d' "${MANIFEST}"

  if grep -q -- '--enable-admission-plugins=' "${MANIFEST}"; then
    sed -i 's/ImagePolicyWebhook,//g; s/,ImagePolicyWebhook//g; s/ImagePolicyWebhook//g' "${MANIFEST}"
  fi
}

stage_test_manifest() {
  mkdir -p /root/17
  cat >/root/17/insecure-image.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: insecure-nginx
  namespace: default
spec:
  containers:
  - name: nginx
    image: nginx:latest
EOF
}

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

ensure_certs
install_webhook
stage_configs
stage_apiserver
stage_test_manifest

wait_api || {
  echo "API server did not become ready during staging" >&2
  exit 1
}

kubectl delete pod insecure-nginx -n default --ignore-not-found >/dev/null 2>&1 || true
