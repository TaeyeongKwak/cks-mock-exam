Cluster security monitoring revealed a container trying to access `/dev/mem`.

Use Falco (or sysdig equivalent workflow) to identify the malicious Pod and its owning Deployment, then stop the workload.

Complete the following:

1. Create a custom Falco rule file at `/root/rule.yaml` to detect open-read/open-write attempts against `/dev/mem`.
2. Run Falco manually with that rule and inspect output to identify the malicious workload.
3. Scale Deployment `mem-hacker` in namespace `default` to `0` replicas.

Notes

- `mem-hacker` is already running in `default`.
- You can use: `falco -r /root/rule.yaml | grep -i dev/mem`
- Focus on the final operational action: stop the malicious workload by scaling the Deployment.

<details>
<summary>Reference Answer Commands</summary>

```bash
cat <<'EOF' > /root/rule.yaml
- rule: read write below /dev/mem
  desc: An attempt to read or write to /dev/mem directory
  condition: >
    ((evt.is_open_read=true or evt.is_open_write=true) and fd.name contains /dev/mem)
  output: "Process %proc.name accessed /dev/mem (command=%proc.cmdline user=%user.name container=%container.id image=%container.image.repository pod_name=%k8s.pod.name namespace=%k8s.ns.name)"
  priority: WARNING
  tags: [security]
EOF

falco -r /root/rule.yaml | grep -i 'dev/mem'
kubectl get pods -n default -l app=mem-hacker -o wide
kubectl scale deployment mem-hacker --replicas=0 -n default
kubectl get deploy mem-hacker -n default
```

</details>