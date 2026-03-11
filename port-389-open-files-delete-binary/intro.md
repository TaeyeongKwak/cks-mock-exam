This scenario rewrites a host-level Linux investigation task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- A service is already listening on TCP port `389`.
- A workspace for this task is staged under `/candidate/14`.

Success criteria

- You identify the PID of the service listening on port `389`.
- You save the process open files to `/candidate/14/files.txt`.
- You locate and delete the executable binary for that service.
