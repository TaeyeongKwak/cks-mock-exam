This scenario rewrites a host-level binary integrity task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- The source node reference `cks-node` is normalized to the actual worker node `node01`.
- The target binaries are staged on `node01` under `/opt/candidate/15a/binaries`.

Adaptation notes

- The original task only requires removing binaries whose sha512 checksums do not match the provided verified values.
- In this staged environment, all four binaries are intentionally mismatched so the learner must identify and delete each one.
- The verified values are also staged on `node01` at `/opt/candidate/15a/verified-sha512.txt` for convenience.

Success criteria

- You verify the sha512 checksums of the four staged binaries on `node01`.
- Every mismatched binary is deleted from `/opt/candidate/15a/binaries`.
- No extra output file is required.
