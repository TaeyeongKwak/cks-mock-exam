#!/bin/bash
set -euo pipefail

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
TARGET_DIR="/opt/candidate/15a/binaries"

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

until ssh ${SSH_OPTS} node01 true >/dev/null 2>&1; do
  sleep 1
done

ssh ${SSH_OPTS} node01 "rm -rf /opt/candidate/15a && mkdir -p ${TARGET_DIR}"

ssh ${SSH_OPTS} node01 "tee /opt/candidate/15a/verified-sha512.txt >/dev/null" <<'EOF'
a3b9e5c4f7d21e89bc317f0e91a7c845df1100d2fb8cc63dff9e40a9e5a2a3c6bb8aa4e4579de9b136d65b18b7d6eae4c3f26de982e537a0a4a1ef8bb1c27c5f  kube-apiserver
b7a223f9918b94e5d6479fcf41da0cd2d93ce0fd102e5c770d1c9b6c82e1a2ad84cbbd54cdd7a4a98fd6133b0b5e6a981a45b0a9cbf24a93980f89ac56c9f47f  kube-controller-manager
4d9917ea90a3f8ccbe3a607f5c9aeeecb7113a9c02a8e55c5bda6f73dd6b5a7c1b928d0169ea3a8b2c5ddbc0285d54a9d76c9c36f7b8ab7b17d5d8f39d1444a2  kube-proxy
8f1c29d7c8b2f491d512accb04a6d028dcdb3fc6a5b7b890f432e77e3217a90d92c2b4a3d98c8d49e19d3f80ad29348db216d31cbf96f82d19976f3251d9b887  kubelet
EOF

ssh ${SSH_OPTS} node01 "tee ${TARGET_DIR}/kube-apiserver >/dev/null" <<'EOF'
#!/bin/sh
echo staged kube-apiserver binary
EOF
ssh ${SSH_OPTS} node01 "tee ${TARGET_DIR}/kube-controller-manager >/dev/null" <<'EOF'
#!/bin/sh
echo staged kube-controller-manager binary
EOF
ssh ${SSH_OPTS} node01 "tee ${TARGET_DIR}/kube-proxy >/dev/null" <<'EOF'
#!/bin/sh
echo staged kube-proxy binary
EOF
ssh ${SSH_OPTS} node01 "tee ${TARGET_DIR}/kubelet >/dev/null" <<'EOF'
#!/bin/sh
echo staged kubelet binary
EOF

ssh ${SSH_OPTS} node01 "chmod +x ${TARGET_DIR}/kube-apiserver ${TARGET_DIR}/kube-controller-manager ${TARGET_DIR}/kube-proxy ${TARGET_DIR}/kubelet"
