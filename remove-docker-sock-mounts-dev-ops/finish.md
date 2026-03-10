Scenario complete.

The vulnerable Deployments in `build-ops` no longer mount `/var/run/docker.sock`, and the running containers cannot access that path anymore.
