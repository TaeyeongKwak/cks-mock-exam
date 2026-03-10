Prevent privileged Pods from being created in namespace `policy-lab`.

Because PodSecurityPolicy is not available on the default Killercoda backend, use the following modern replacement:

1. Create a `ValidatingAdmissionPolicy` named `prevent-privileged-policy` that rejects privileged Pods.
2. Create a `ValidatingAdmissionPolicyBinding` named `prevent-privileged-binding` that applies the policy only to namespace `policy-lab`.
3. Create ServiceAccount `psp-sa` in namespace `policy-lab`.
4. Create ClusterRole `prevent-role` that allows creating Pods.
5. Create ClusterRoleBinding `prevent-role-binding` that binds `prevent-role` to ServiceAccount `psp-sa`.
6. Verify the policy by attempting to create the staged privileged Pod manifest `/root/policy-lab/privileged-pod.yaml`.

Notes

- Helper manifests are staged at `/root/policy-lab/privileged-pod.yaml` and `/root/policy-lab/non-privileged-pod.yaml`.
- Keep the resource names exactly as requested.
- The verification should show that RBAC allows Pod creation but the admission policy blocks the privileged Pod in `policy-lab`.
