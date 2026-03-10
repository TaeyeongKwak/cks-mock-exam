There is an existing Pod named `web-pod` in namespace `qa-system`.

Complete the following tasks:

1. Fetch the Pod's ServiceAccount name and save it to `/candidate/current-sa.txt`.
2. Create a Role in namespace `qa-system` that can `get`, `list`, and `watch` `deployments`.
3. Bind that Role to the ServiceAccount used by `web-pod`.

Notes

- The Role and RoleBinding names are up to you.
- Use namespace `qa-system`.
- The terminal starts on `controlplane`.
