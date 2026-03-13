#!/bin/bash
set -euo pipefail

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

until ssh ${SSH_OPTS} node01 true >/dev/null 2>&1; do
  sleep 1
done

ssh ${SSH_OPTS} node01 "mkdir -p /home/anomalous && rm -f /home/anomalous/report"
ssh ${SSH_OPTS} node01 "export DEBIAN_FRONTEND=noninteractive; apt-get update -y >/dev/null && apt-get install -y curl >/dev/null"
ssh ${SSH_OPTS} node01 "if ! command -v falco >/dev/null 2>&1; then curl -fsSL https://falco.org/script/install | bash >/dev/null 2>&1; apt-get install -y falco >/dev/null; fi"

kubectl delete pod tomcat --ignore-not-found >/dev/null 2>&1 || true

cat >/root/tomcat-pod.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: tomcat
spec:
  nodeName: node01
  containers:
  - name: tomcat
    image: busybox:1.36
    command:
    - sh
    - -c
    - |
      while true; do
        id >/dev/null 2>&1
        sleep 11
        uname -a >/dev/null 2>&1
        sleep 11
        wget -q -O- http://127.0.0.1:1 >/dev/null 2>&1 || true
        sleep 11
        sh -c 'echo anomaly >/dev/null'
        sleep 11
      done
EOF

kubectl apply -f /root/tomcat-pod.yaml >/dev/null
kubectl wait --for=condition=Ready pod/tomcat --timeout=180s >/dev/null
