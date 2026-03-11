This scenario rewrites a ServiceAccount policy task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- Namespace `qa-lab` already exists.
- The Pod manifest to edit is staged at `/home/candidate/11/ui-pod.yaml`.

Success criteria

- ServiceAccount `ui-sa` exists in namespace `qa-lab`.
- `ui-sa` has `automountServiceAccountToken: false`.
- The Pod from `/home/candidate/11/ui-pod.yaml` is applied successfully and uses `ui-sa`.
- The unused staged ServiceAccounts in `qa-lab` are removed.
