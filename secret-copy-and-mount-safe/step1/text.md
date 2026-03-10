Complete the following task:

1. Retrieve the contents of the existing Secret `root-admin` in namespace `vault`.
2. Store the decoded fields in local files:
   - `username` -> `/root/secret-lab/username.txt`
   - `password` -> `/root/secret-lab/password.txt`
3. Create a new Secret `app-secret` in namespace `vault` with:
   - `username=dbadmin`
   - `password=moresecurepas`
4. Create a Pod named `secret-mount-pod` in namespace `vault` that mounts Secret `app-secret`.

Constraints

- Both local files must be created during this task.
- Create the new Secret and Pod independently from the local files.
