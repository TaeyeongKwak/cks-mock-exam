This scenario rewrites a Kubernetes NetworkPolicy task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- The target Pod `catalog-service` already runs in namespace `app-team`.
- Test client Pods are already running in multiple namespaces.

Adaptation notes

- In Kubernetes NetworkPolicy, matching labeled Pods in any namespace requires `namespaceSelector` together with `podSelector`.
- This scenario validates the policy by testing real connectivity to `catalog-service`.

Success criteria

- A NetworkPolicy named `ingress-guard` exists in namespace `app-team`.
- It applies to Pod `catalog-service`.
- It allows ingress only from Pods in `app-team` and Pods labeled `environment=testing` from any namespace.
- Other ingress traffic is blocked.
