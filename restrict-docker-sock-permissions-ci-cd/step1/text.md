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
