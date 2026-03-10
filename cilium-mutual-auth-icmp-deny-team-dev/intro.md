This lab centers on authoring Cilium policy resources in a staged namespace.

Prepared environment

- You start on `controlplane`.
- Namespace `mesh-zone` already contains four Deployments and two Services.
- A baseline `CiliumNetworkPolicy` named `mesh-open` is already present.

Scenario notes

- The cluster does not depend on a live Cilium datapath for scoring; policy resources are evaluated deterministically.
- One traffic path should require authentication between application tiers.
- A separate path should block ICMP egress from a diagnostics workload to an internal echo service.

Completion target

- Two new namespaced `CiliumNetworkPolicy` objects implement the required behavior.
- The baseline `mesh-open` policy remains untouched.
