Enable Istio mutual TLS in `STRICT` mode for all workloads in namespace `billing`.

Complete the following task:

1. Verify that automatic Istio sidecar injection is enabled for namespace `billing`.
2. Create a namespace-wide `PeerAuthentication` policy in `billing` that enforces `STRICT` mTLS.
3. Use `/root/billing-peerauth.yaml` for the policy manifest.
4. Confirm that the workloads in `billing` communicate using mTLS after enforcement.

Notes

- Sample workloads `httpbin` and `curl` are already deployed in `billing`.
- Both workloads should keep working after you enforce `STRICT` mTLS.
- You may use `curl` from the `curl` Pod to the `httpbin` Service to confirm the traffic mode.

<details>
<summary>Reference Answer Commands</summary>

```bash
kubectl label namespace billing istio-injection=enabled --overwrite
vi /root/billing-peerauth.yaml
# Use a namespace-wide PeerAuthentication in billing with:
# spec:
#   mtls:
#     mode: STRICT
kubectl apply -f /root/billing-peerauth.yaml
kubectl rollout restart deployment/httpbin -n billing
kubectl rollout restart deployment/curl -n billing
kubectl rollout status deployment/httpbin -n billing --timeout=180s
kubectl rollout status deployment/curl -n billing --timeout=180s
CURL_POD=$(kubectl get pods -n billing -l app=curl -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n billing "$CURL_POD" -c curl -- curl -fsS http://httpbin.billing:8000/headers
```

</details>

