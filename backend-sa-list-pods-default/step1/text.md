Create a lightweight namespace-scoped identity for Pod inventory work in `default`.

Tasks

1. Create a ServiceAccount named `viewer-sa`.
2. Create a Role named `pod-viewer` in `default` that grants only `list` on `pods`.
3. Create a RoleBinding named `pod-viewer-bind` that attaches that Role to `viewer-sa`.
4. Launch a Pod named `inventory-shell` in `default` that uses `viewer-sa`.

Constraints

- Keep all resources in namespace `default`.
- The Pod only needs to stay running.
- Do not grant extra Pod verbs beyond what is required.
