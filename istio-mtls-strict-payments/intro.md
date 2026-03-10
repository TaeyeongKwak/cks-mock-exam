This scenario rewrites an Istio mutual TLS task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- Istio is installed during scenario setup.
- The namespace `billing` is already created and prepared for automatic sidecar injection.
- Two sample workloads are deployed in `billing`: `httpbin` and `curl`.

Adaptation notes

- The verification of sidecar injection is done through the namespace label and by checking that the running Pods include the `istio-proxy` sidecar.
- The verification of mTLS uses the `X-Forwarded-Client-Cert` header exposed by `httpbin`, following the Istio authentication documentation.
- A helper manifest path `/root/billing-peerauth.yaml` is reserved for your PeerAuthentication policy.

Success criteria

- Automatic sidecar injection is enabled for namespace `billing`.
- A namespace-wide `PeerAuthentication` enforces `STRICT` mTLS in `billing`.
- The workloads in `billing` communicate successfully using mTLS.
