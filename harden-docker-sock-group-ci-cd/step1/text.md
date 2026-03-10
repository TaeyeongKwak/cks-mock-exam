There is a Deployment in namespace `ci-ops` whose Pod mounts `/var/run/docker.sock` from the host.

The mounted socket is staged with permissions equivalent to `root:docker` and `0660`. In the current Pod configuration, the container can access that socket because it is a member of the host's Docker group.

Complete the following task:

1. Identify the vulnerable Deployment in namespace `ci-ops`.
2. Update its Pod template so the running container is no longer a member of the Docker socket group.
3. Keep the existing `/var/run/docker.sock` hostPath volume and mount in place.
4. Roll out the change and ensure the new Pod can no longer read or write `/var/run/docker.sock`.

Notes

- The helper manifest is staged at `/root/ci-ops-deployment.yaml`.
- In this scenario, group ID `123` represents the host `docker` group.
- Do not replace the Deployment with another resource kind.
