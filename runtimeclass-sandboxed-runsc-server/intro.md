This scenario rewrites a Kubernetes RuntimeClass task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- The cluster uses containerd.
- The `runsc` runtime handler is prepared on `controlplane`.
- The namespace `backend` already contains Pods.

Success criteria

- A `RuntimeClass` named `isolated` exists and uses handler `runsc`.
- All Pods in namespace `backend` use `runtimeClassName: isolated`.
- The updated Pods are running successfully.
