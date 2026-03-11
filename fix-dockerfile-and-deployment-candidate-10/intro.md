This scenario covers a file-review hardening task in the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- The files to edit are staged at `/home/candidate/10-sec/Dockerfile` and `/home/candidate/10-sec/deployment.yaml`.
- You only need to edit the files. You do not need to build the image or apply the Deployment.

Success criteria

- The Dockerfile uses a pinned Ubuntu base image and no longer runs as root at runtime.
- The Deployment uses a supported MySQL image tag and no longer runs as UID `0`.
- No settings are added or removed from either file.
