Use Falco on worker node `node01` to monitor container process execution activity.

Complete the following task:

1. Create a Falco rule that detects newly spawned or executed processes in containers by matching `spawned_process and container`.
2. Restart the Falco service so the updated rule is loaded.
3. Monitor the container workload on `node01` for at least 30 seconds.
4. Store detected incidents in `/opt/node-01/alerts/details` on `node01`.
5. Use this exact line format:
   - `timestamp,uid/username,processName`

Notes

- Falco is already installed on `node01`.
- Write your custom rule in `/etc/falco/falco_rules.local.yaml`.
- Restart Falco with `systemctl restart falco.service` after editing the rule file.
- You may inspect service health with `systemctl status falco.service --no-pager`.
- The workload in namespace `runtime-lab` is already running on `node01` and continuously spawns short-lived processes.
- Use an output string that includes `%evt.time`, `%user.uid` or `%user.name`, and `%proc.name` in CSV order.

<details>
<summary>Show answer</summary>

```bash
ssh node01
sudo -i

cat >/etc/falco/falco_rules.local.yaml <<'EOF'
- rule: Container Process Execution
  desc: Detect spawned processes in containers
  condition: spawned_process and container
  output: "%evt.time,%user.uid,%proc.name"
  priority: NOTICE
EOF

falco -V -r /etc/falco/falco_rules.yaml -r /etc/falco/falco_rules.local.yaml
systemctl restart falco.service
systemctl status falco.service --no-pager
/usr/local/bin/falco-report-csv 35 /opt/node-01/alerts/details
tail -n 5 /opt/node-01/alerts/details
```

</details>
