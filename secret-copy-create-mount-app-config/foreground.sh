#!/bin/bash
set -euo pipefail

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

kubectl create namespace dev-sec --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl create namespace portal --dry-run=client -o yaml | kubectl apply -f - >/dev/null

kubectl delete secret default-token-alpha -n dev-sec --ignore-not-found >/dev/null 2>&1 || true
kubectl delete secret web-config-secret -n portal --ignore-not-found >/dev/null 2>&1 || true
kubectl delete pod web-config-pod -n portal --ignore-not-found >/dev/null 2>&1 || true
rm -f /root/cluster-ca.crt

kubectl create secret generic default-token-alpha -n dev-sec \
  --from-literal=ca.crt='-----BEGIN CERTIFICATE-----
MIIBszCCAVmgAwIBAgIUDemoKillercodaMockCAData1234567890ABCDMAoGCCqG
SM49BAMCMBQxEjAQBgNVBAMMCWt1YmUtY2EtbW9jazAeFw0yNjAzMTEwMDAwMDBa
Fw0zNjAzMDgwMDAwMDBaMBQxEjAQBgNVBAMMCWt1YmUtY2EtbW9jazBZMBMGByqG
SM49AgEGCCqGSM49AwEHA0IABKd0lR4D7mQKxR2V4dZ1sT2BtdummyCertDatax7xv
0rVw1bA8XQk8t7g0p0wYp9c6nA3j9m2J6F3m7R1nQmJd4x2jUzBRMB0GA1UdDgQWBB
TjF5g8mockcertlinezzzzzzzzzzzzzzzzDAfBgNVHSMEGDAWgBTjF5g8mockcert
linezzzzzzzzzzzzzzzzDAPBgNVHRMBAf8EBTADAQH/MAoGCCqGSM49BAMCA0cAME
QCIB4q0mockedcertificatecontentzzzzzzzzzzAiA4K9eO6mockedcertificate
contentyyyyyyyyyyyyyyyyyyyy=
-----END CERTIFICATE-----' >/dev/null

cat >/root/web-config-pod.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: web-config-pod
  namespace: portal
spec:
  nodeName: controlplane
  containers:
  - name: nginx
    image: nginx:1.27
    volumeMounts:
    - name: app-config
      mountPath: /etc/app-config
  volumes:
  - name: app-config
    secret:
      secretName: placeholder-secret
EOF
