Create a NetworkPolicy named `ingress-guard` in namespace `app-team` to restrict access to Pod `catalog-service`.

Requirements

- Allow ingress from Pods in the same namespace `app-team`.
- Allow ingress from Pods with label `environment=testing` in any namespace.
- Do not allow other ingress traffic.

Notes

- The target Pod `catalog-service` is already running in `app-team`.
- Test client Pods are already running in `app-team`, `qa-lab`, and `misc-team`.
- You only need to create the NetworkPolicy.
