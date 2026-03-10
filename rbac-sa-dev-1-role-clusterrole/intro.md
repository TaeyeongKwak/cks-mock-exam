This scenario prepares RBAC resources in namespace `access-lab`.

Adaptation notes

- The playground uses the default two-node kubeadm cluster.
- The ServiceAccount `sa-app-1` and Pod `frontend-pod` are pre-created in namespace `access-lab`.
- An existing namespaced Role is already bound to `sa-app-1`, but it is over-permissive and must be corrected.
