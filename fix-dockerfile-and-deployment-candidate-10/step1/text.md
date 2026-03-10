Review and correct the staged files in `/home/candidate/10-sec`.

Files

- `/home/candidate/10-sec/Dockerfile`
- `/home/candidate/10-sec/deployment.yaml`

Requirements

- Fix two existing settings in the Dockerfile.
- Fix two existing settings in the Deployment manifest.
- Do not add or remove settings. Only modify existing values.
- Use UID `65535` for the unprivileged runtime user.

Notes

- In this scenario, the Dockerfile issues to fix are the floating Ubuntu base tag and the final runtime user.
- In this scenario, the Deployment issues to fix are the MySQL image tag and `securityContext.runAsUser`.
- The files only need to be valid after your edits. You do not need to build or deploy anything.
