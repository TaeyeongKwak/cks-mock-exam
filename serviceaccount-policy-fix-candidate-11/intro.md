This scenario rewrites a ServiceAccount policy task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- Namespace `qa-lab` already exists.
- The Pod manifest to edit is staged at `/home/candidate/11/ui-pod.yaml`.

Adaptation notes

- The staged Pod manifest references a non-existent ServiceAccount, so applying it fails until you correct the manifest.
- The organization policy for this scenario is:
  - ServiceAccounts must not automount API credentials
  - ServiceAccount names must end with `-sa`
- Namespace `qa-lab` also contains unused ServiceAccounts that should be cleaned up.

Success criteria

- ServiceAccount `ui-sa` exists in namespace `qa-lab`.
- `ui-sa` has `automountServiceAccountToken: false`.
- The Pod from `/home/candidate/11/ui-pod.yaml` is applied successfully and uses `ui-sa`.
- The unused staged ServiceAccounts in `qa-lab` are removed.
