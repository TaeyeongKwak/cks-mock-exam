Restrict Pod volumes in namespace `policy-zone`.

Because PodSecurityPolicy is not available on the default Killercoda backend, use the following modern replacement:

1. Create a `ValidatingAdmissionPolicy` named `prevent-volume-policy` that allows only `persistentVolumeClaim` volumes for Pods.
2. Create a `ValidatingAdmissionPolicyBinding` named `prevent-volume-policy-binding` that applies the policy only to namespace `policy-zone`.
3. Create ServiceAccount `psp-sa` in namespace `policy-zone`.
4. Create ClusterRole `psp-role` that allows creating Pods.
5. Create ClusterRoleBinding `psp-role-binding` that binds `psp-role` to ServiceAccount `psp-sa`.
6. Verify the configuration by attempting to create the staged Secret-volume Pod manifest `/root/policy-zone/secret-volume-pod.yaml`.

Notes

- A helper manifest that should be allowed is staged at `/root/policy-zone/pvc-volume-pod.yaml`.
- Keep the resource names exactly as requested.
- The verification should show that RBAC allows Pod creation but the admission policy blocks Secret volumes in `policy-zone`.
