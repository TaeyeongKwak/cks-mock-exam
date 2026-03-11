This scenario rewrites an Istio mutual TLS task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- Istio is installed during scenario setup.
- The namespace `billing` is already created and prepared for automatic sidecar injection.
- Two sample workloads are deployed in `billing`: `httpbin` and `curl`.

Success criteria

- Automatic sidecar injection is enabled for namespace `billing`.
- A namespace-wide `PeerAuthentication` enforces `STRICT` mTLS in `billing`.
- The workloads in `billing` communicate successfully using mTLS.
