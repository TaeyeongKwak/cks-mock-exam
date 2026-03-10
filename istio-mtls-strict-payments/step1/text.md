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
