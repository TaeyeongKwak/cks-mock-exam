This lab starts with a small batch namespace that already contains several standalone Pods.

Environment notes

- You begin on `controlplane`.
- The target namespace for this rewrite is `shipping`.
- Each Pod in `shipping` was created directly, so deleting it removes it permanently.

Success criteria

- Every rejected Pod in `shipping` is gone.
- Approved Pods remain available.
