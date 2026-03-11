Identify the service listening on TCP port `389` and investigate it.

Complete the following task:

1. Find the PID of the service listening on port `389`.
2. Store the full list of open files for that process in `/candidate/14/files.txt`.
3. Locate the executable binary of that process and delete it.

Notes

- A workspace for this task is available under `/candidate/14`.
- `lsof` is installed if you want to use it.
- Do not move the output file to another location.

<details>
<summary>Reference Answer Commands</summary>

```bash
PID=$(sudo lsof -iTCP:389 -sTCP:LISTEN -t)
sudo lsof -p "$PID" > /candidate/14/files.txt
BIN=$(readlink -f /proc/$PID/exe)
sudo rm -f "$BIN"
cat /candidate/14/files.txt
```

</details>

