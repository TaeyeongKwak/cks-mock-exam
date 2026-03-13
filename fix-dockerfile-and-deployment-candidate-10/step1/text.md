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
- Pin the Dockerfile base image to `ubuntu:16.04`.
- In this scenario, the Deployment issues to fix are the MySQL image tag and `securityContext.runAsUser`.
- Update the Deployment image to `mysql:8.0`.
- Set the Deployment container `securityContext.runAsUser` to `65535`.
- The files only need to be valid after your edits. You do not need to build or deploy anything.

<details>
<summary>Reference Answer Commands</summary>

```bash
vi /home/candidate/10-sec/Dockerfile
# Change the base image to ubuntu:16.04
# Change the last USER instruction to: USER 65535
vi /home/candidate/10-sec/deployment.yaml
# Change the container image to mysql:8.0
# Change securityContext.runAsUser to 65535
kubectl apply --dry-run=client -f /home/candidate/10-sec/deployment.yaml
grep -E '^(FROM|USER)' /home/candidate/10-sec/Dockerfile
kubectl create --dry-run=client -f /home/candidate/10-sec/deployment.yaml -o jsonpath='{.spec.template.spec.containers[0].image}{" "}{.spec.template.spec.containers[0].securityContext.runAsUser}{"\n"}'
```

</details>

