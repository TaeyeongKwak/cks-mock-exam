This lab stages a namespace that must be isolated from the rest of the cluster.

Environment notes

- You begin on `controlplane`.
- The namespace to lock down in this rewrite is `quarantine`.
- A separate namespace named `edge` exists so you can reason about cross-namespace traffic.

Adaptation notes

- Sample client and server Pods are precreated so the final policy can be verified by behavior, not only by YAML shape.
- You only need one NetworkPolicy for the target namespace.

Success criteria

- Create a policy named `air-gap` in `quarantine`.
- It must select every Pod in `quarantine`.
- It must deny both incoming and outgoing traffic for that namespace.
