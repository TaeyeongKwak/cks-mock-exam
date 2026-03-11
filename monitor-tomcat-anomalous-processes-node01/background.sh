#!/bin/bash
set -euo pipefail

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

kubectl wait --for=condition=Ready node/controlplane node/node01 --timeout=180s >/dev/null

until ssh ${SSH_OPTS} node01 true >/dev/null 2>&1; do
  sleep 1
done

ssh ${SSH_OPTS} node01 "mkdir -p /home/anomalous && rm -f /home/anomalous/report"

ssh ${SSH_OPTS} node01 "tee /usr/local/bin/tomcat-proc-watch >/dev/null" <<'EOF'
#!/usr/bin/env python3
import datetime
import json
import subprocess
import sys
import time

duration = int(sys.argv[1]) if len(sys.argv) > 1 else 45
interval = 1.0
container_name = "tomcat"
seen = set()
initialized = False
start = time.time()

def run(cmd):
    try:
        return subprocess.check_output(cmd, stderr=subprocess.DEVNULL, text=True)
    except subprocess.CalledProcessError:
        return ""

while time.time() - start < duration:
    current = set()
    container_ids = run(["crictl", "ps", "--name", container_name, "-q"]).split()
    for cid in container_ids:
        inspect_raw = run(["crictl", "inspect", cid])
        if not inspect_raw:
            continue
        try:
            inspect = json.loads(inspect_raw)
        except json.JSONDecodeError:
            continue
        if isinstance(inspect, list) and inspect:
            inspect = inspect[0]

        pid = (
            inspect.get("info", {}).get("pid")
            or inspect.get("status", {}).get("pid")
            or inspect.get("pid")
        )
        if not pid:
            continue

        ps_out = run(["nsenter", "-t", str(pid), "-p", "ps", "-eo", "pid,uid,comm", "--no-headers"])
        if not ps_out:
            continue

        for line in ps_out.splitlines():
            parts = line.split(None, 2)
            if len(parts) != 3:
                continue
            proc_pid, uid, comm = parts
            key = (cid, proc_pid, uid, comm)
            current.add(key)
            if initialized and key not in seen:
                ts = datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")
                print(f"{ts},{uid},{comm}", flush=True)

    seen = current
    initialized = True
    time.sleep(interval)
EOF

ssh ${SSH_OPTS} node01 "chmod +x /usr/local/bin/tomcat-proc-watch"

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
