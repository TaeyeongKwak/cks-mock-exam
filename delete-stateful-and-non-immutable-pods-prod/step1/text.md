An internal review tagged several standalone Pods in namespace `shipping` for retirement.

Task

- Remove every Pod in `shipping` that violates either of these rules:
  - it uses writable scratch storage through `emptyDir`
  - it runs privileged
  - it keeps the container root filesystem writable

Constraints

- Keep approved Pods running.
- Do not replace deleted Pods with new resources.
- Treat this as a cleanup job, not a refactor.
