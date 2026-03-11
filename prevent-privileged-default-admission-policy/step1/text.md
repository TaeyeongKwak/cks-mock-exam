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

<details>
<summary>Reference Answer Commands</summary>

```bash
kubectl create serviceaccount psp-sa -n policy-lab --dry-run=client -o yaml | kubectl apply -f -
kubectl create clusterrole prevent-role --verb=create --resource=pods --dry-run=client -o yaml | kubectl apply -f -
kubectl create clusterrolebinding prevent-role-binding --clusterrole=prevent-role --serviceaccount=policy-lab:psp-sa --dry-run=client -o yaml | kubectl apply -f -
cat <<'EOF' >/tmp/prevent-privileged-policy.yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: prevent-privileged-policy
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
    - apiGroups: [""]
      apiVersions: ["v1"]
      operations: ["CREATE"]
      resources: ["pods"]
  validations:
  - expression: "object.spec.containers.all(c, !has(c.securityContext) || !has(c.securityContext.privileged) || c.securityContext.privileged == false)"
    message: "privileged containers are not allowed"
EOF
kubectl apply -f /tmp/prevent-privileged-policy.yaml
cat <<'EOF' >/tmp/prevent-privileged-binding.yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: prevent-privileged-binding
spec:
  policyName: prevent-privileged-policy
  validationActions: [Deny]
  matchResources:
    namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: policy-lab
EOF
kubectl apply -f /tmp/prevent-privileged-binding.yaml
kubectl apply --dry-run=server --as=system:serviceaccount:policy-lab:psp-sa -f /root/policy-lab/non-privileged-pod.yaml
kubectl apply --dry-run=server --as=system:serviceaccount:policy-lab:psp-sa -f /root/policy-lab/privileged-pod.yaml || true
```

</details>

