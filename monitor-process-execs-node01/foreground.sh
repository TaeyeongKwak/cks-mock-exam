#!/bin/bash
set -euo pipefail

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

until ssh ${SSH_OPTS} node01 true >/dev/null 2>&1; do
  sleep 1
done

ssh ${SSH_OPTS} node01 "mkdir -p /opt/node-01/reports && rm -f /opt/node-01/reports/events"

ssh ${SSH_OPTS} node01 "tee /usr/local/bin/container-proc-watch >/dev/null" <<'EOF'
#!/usr/bin/env python3
import datetime
import json
import subprocess
import sys
import time

duration = int(sys.argv[1]) if len(sys.argv) > 1 else 30
interval = 1.0

def run(cmd):
    try:
        return subprocess.check_output(cmd, stderr=subprocess.DEVNULL, text=True)
    except subprocess.CalledProcessError:
        return ""

seen = set()
initialized = False
start = time.time()

while time.time() - start < duration:
    current = set()
    container_ids = run(["crictl", "ps", "-q"]).split()
    for cid in container_ids:
        inspect_raw = run(["crictl", "inspect", cid])
        if not inspect_raw:
            continue
        try:
            inspect = json.loads(inspect_raw)
        except json.JSONDecodeError:
            continue

        pid = None
        if isinstance(inspect, list) and inspect:
            inspect = inspect[0]
        pid = (
            inspect.get("info", {}).get("pid")
            or inspect.get("status", {}).get("pid")
            or inspect.get("pid")
        )
        if not pid:
            continue

        ps_out = run(["nsenter", "-t", str(pid), "-p", "ps", "-eo", "pid,user,comm", "--no-headers"])
        if not ps_out:
            continue

        for line in ps_out.splitlines():
            parts = line.split(None, 2)
            if len(parts) != 3:
                continue
            proc_pid, user, comm = parts
            key = (cid, proc_pid, user, comm)
            current.add(key)
            if initialized and key not in seen:
                ts = datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")
                print(f"{ts},{user},{comm}", flush=True)

    seen = current
    initialized = True
    time.sleep(interval)
EOF

ssh ${SSH_OPTS} node01 "chmod +x /usr/local/bin/container-proc-watch"

kubectl create namespace proc-watch --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete deployment root-spawner uid1001-spawner uid1002-spawner -n proc-watch --ignore-not-found >/dev/null 2>&1 || true

cat <<'EOF' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: root-spawner
  namespace: proc-watch
spec:
  replicas: 1
  selector:
    matchLabels:
      app: root-spawner
  template:
    metadata:
      labels:
        app: root-spawner
    spec:
      nodeName: node01
      containers:
      - name: root-spawner
        image: busybox:1.36
        command:
        - sh
        - -c
        - |
          while true; do
            sh -c "sleep 1" >/dev/null 2>&1
            sleep 7
          done
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: uid1001-spawner
  namespace: proc-watch
spec:
  replicas: 1
  selector:
    matchLabels:
      app: uid1001-spawner
  template:
    metadata:
      labels:
        app: uid1001-spawner
    spec:
      nodeName: node01
      securityContext:
        runAsUser: 1001
      containers:
      - name: uid1001-spawner
        image: busybox:1.36
        command:
        - sh
        - -c
        - |
          while true; do
            sleep 2
            sleep 6
          done
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: uid1002-spawner
  namespace: proc-watch
spec:
  replicas: 1
  selector:
    matchLabels:
      app: uid1002-spawner
  template:
    metadata:
      labels:
        app: uid1002-spawner
    spec:
      nodeName: node01
      securityContext:
        runAsUser: 1002
      containers:
      - name: uid1002-spawner
        image: busybox:1.36
        command:
        - sh
        - -c
        - |
          while true; do
            wget -q -O- http://127.0.0.1:1 >/dev/null 2>&1 || true
            sleep 8
          done
EOF

kubectl rollout status deployment/root-spawner -n proc-watch --timeout=180s >/dev/null
kubectl rollout status deployment/uid1001-spawner -n proc-watch --timeout=180s >/dev/null
kubectl rollout status deployment/uid1002-spawner -n proc-watch --timeout=180s >/dev/null
