This lab starts with a small batch namespace that already contains several standalone Pods.

Environment notes

- You begin on `controlplane`.
- The target namespace for this rewrite is `shipping`.
- Each Pod in `shipping` was created directly, so deleting it removes it permanently.

Adaptation notes

- For this version, a Pod is treated as mutable if it mounts writable scratch storage through `emptyDir`.
- A Pod also fails the review if it runs privileged or if its container root filesystem is writable.
- The exercise is only about identifying which Pods must be retired.

Success criteria

- Every rejected Pod in `shipping` is gone.
- Approved Pods remain available.
