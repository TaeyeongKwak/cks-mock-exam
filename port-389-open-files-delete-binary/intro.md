This scenario rewrites a host-level Linux investigation task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- A service is already listening on TCP port `389`.
- A workspace for this task is staged under `/candidate/14`.

Adaptation notes

- The listening service is a custom executable staged specifically for this scenario so the binary can be safely deleted.
- The required output path `/candidate/14/files.txt` is preserved exactly as requested.
- `lsof` is installed during setup so you can capture the process open files directly if you choose.

Success criteria

- You identify the PID of the service listening on port `389`.
- You save the process open files to `/candidate/14/files.txt`.
- You locate and delete the executable binary for that service.
