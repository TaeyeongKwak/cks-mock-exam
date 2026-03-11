Deployment `build-runner` in namespace `ci-sec` mounts `/var/run/docker.sock` into both containers.

The mounted file currently behaves like `root:docker` with mode `0660`, so both containers can access it through the Docker group. This is too permissive.

Complete the following task:

1. Restrict access so only the intended CI container user can access `/var/run/docker.sock`.
2. Change the ownership and group of the mounted file to UID `1000` and GID `1000`.
3. Change the file mode so only that intended user can access it.
4. Ensure the `builder` container can still access the socket.
5. Ensure the `observer` container can no longer read or write the socket.

Notes

- The helper manifest is staged at `/root/build-runner.yaml`.
- In this scenario, GID `123` represents the host `docker` group.
- Use access to `/var/run/docker.sock` as the proxy for Docker daemon control.

<details>
<summary>Reference Answer Commands</summary>

```bash
# Inspect the current Deployment
kubectl get deploy build-runner -n ci-sec -o yaml > /tmp/build-runner-current.yaml

# Update the staged manifest so an initContainer locks down the mounted socket
vi /root/build-runner.yaml

# In /root/build-runner.yaml:
# 1. Keep the existing hostPath volume that mounts /var/run/docker.sock
# 2. Add an initContainer that mounts the same volume and runs:
#    chown 1000:1000 /var/run/docker.sock && chmod 600 /var/run/docker.sock
# 3. Keep the builder container running as UID 1000 so it can still use the socket
# 4. Keep the observer container as a different user so it loses access

# Apply the updated manifest
kubectl apply -f /root/build-runner.yaml
kubectl rollout status deployment/build-runner -n ci-sec --timeout=180s

# Validate the file metadata and access from both containers
POD=$(kubectl get pods -n ci-sec -l app=build-runner -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n ci-sec -c builder "$POD" -- sh -c "stat -c '%u:%g %a' /var/run/docker.sock"
kubectl exec -n ci-sec -c builder "$POD" -- sh -c '[ -r /var/run/docker.sock ] && [ -w /var/run/docker.sock ] && echo allowed'
kubectl exec -n ci-sec -c observer "$POD" -- sh -c 'if [ -r /var/run/docker.sock ] || [ -w /var/run/docker.sock ]; then echo allowed; else echo blocked; fi'
```

</details>

