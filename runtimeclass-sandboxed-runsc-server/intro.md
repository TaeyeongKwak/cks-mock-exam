This scenario rewrites a Kubernetes RuntimeClass task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- The cluster uses containerd.
- The `runsc` runtime handler is prepared on `controlplane`.
- The namespace `backend` already contains Pods.

Adaptation notes

- The source file path `/home/candidate/10/runtime-class.yaml` is normalized to `/root/10/isolated-class.yaml`.
- Pod `runtimeClassName` changes are treated as recreate-and-reapply operations in this scenario, so a helper manifest is staged at `/root/10/backend-pods.yaml`.
- The staged Pods are pinned to `controlplane` so the exercise only depends on the node prepared with `runsc`.

Success criteria

- A `RuntimeClass` named `isolated` exists and uses handler `runsc`.
- All Pods in namespace `backend` use `runtimeClassName: isolated`.
- The updated Pods are running successfully.
