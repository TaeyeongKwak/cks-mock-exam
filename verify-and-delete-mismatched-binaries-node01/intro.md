This scenario rewrites a host-level binary integrity task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- The target binaries are staged on `node01` under `/opt/candidate/15a/binaries`.

Success criteria

- You verify the sha512 checksums of the four staged binaries on `node01`.
- Every mismatched binary is deleted from `/opt/candidate/15a/binaries`.
- No extra output file is required.
