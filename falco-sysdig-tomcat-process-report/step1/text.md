Use Falco on worker node `node01` to observe Pod `tomcat`.

Complete the following task:

1. Create a Falco rule that detects newly spawned or executed processes from the single-container Pod `tomcat` by matching `spawned_process and container and k8s.pod.name=tomcat`.
2. Restart the Falco service so the updated rule is loaded.
3. Monitor the Pod on worker node `node01` for at least 40 seconds.
4. Save the detected incidents on `node01` in `/home/anomalous/report`.
5. Use this exact line format:
   - `[timestamp],[uid],[processName]`

Notes

- Falco is already installed on `node01`.
- Write your custom rule in `/etc/falco/falco_rules.local.yaml`.
- Restart Falco with `systemctl restart falco.service` after editing the rule file.
- You may inspect service health with `systemctl status falco.service --no-pager`.
- The target Pod runs in namespace `default` on `node01`.
- Keep the report file on the worker node.
- Use an output string that includes `%evt.time`, `%user.uid` or `%user.name`, and `%proc.name` in bracketed order.

<details>
<summary>Show answer</summary>

```bash
ssh node01
sudo -i

cat >/etc/falco/falco_rules.local.yaml <<'EOF'
- rule: Tomcat Process Activity
  desc: Detect spawned processes in pod tomcat
  condition: spawned_process and container and k8s.pod.name=tomcat
  output: "[%evt.time],[%user.uid],[%proc.name]"
  priority: NOTICE
EOF

falco -V -r /etc/falco/falco_rules.yaml -r /etc/falco/falco_rules.local.yaml
systemctl restart falco.service
systemctl status falco.service --no-pager
/usr/local/bin/falco-report-bracket 45 /home/anomalous/report
tail -n 5 /home/anomalous/report
```

</details>
