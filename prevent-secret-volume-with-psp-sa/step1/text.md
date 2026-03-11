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

<details>
<summary>Reference Answer Commands</summary>

```bash
kubectl create serviceaccount psp-sa -n policy-zone --dry-run=client -o yaml | kubectl apply -f -
kubectl create clusterrole psp-role --verb=create --resource=pods --dry-run=client -o yaml | kubectl apply -f -
kubectl create clusterrolebinding psp-role-binding --clusterrole=psp-role --serviceaccount=policy-zone:psp-sa --dry-run=client -o yaml | kubectl apply -f -
cat <<'EOF' >/tmp/prevent-volume-policy.yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: prevent-volume-policy
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
    - apiGroups: [""]
      apiVersions: ["v1"]
      operations: ["CREATE"]
      resources: ["pods"]
  validations:
  - expression: "!has(object.spec.volumes) || object.spec.volumes.all(v, has(v.persistentVolumeClaim))"
    message: "only persistentVolumeClaim volumes are allowed"
EOF
kubectl apply -f /tmp/prevent-volume-policy.yaml
cat <<'EOF' >/tmp/prevent-volume-policy-binding.yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: prevent-volume-policy-binding
spec:
  policyName: prevent-volume-policy
  validationActions: [Deny]
  matchResources:
    namespaceSelector:
      matchLabels:
        volume-policy: policy-zone
EOF
kubectl apply -f /tmp/prevent-volume-policy-binding.yaml
kubectl label namespace policy-zone volume-policy=policy-zone --overwrite
kubectl apply --dry-run=server --as=system:serviceaccount:policy-zone:psp-sa -f /root/policy-zone/pvc-volume-pod.yaml
kubectl apply --dry-run=server --as=system:serviceaccount:policy-zone:psp-sa -f /root/policy-zone/secret-volume-pod.yaml || true
```

</details>

