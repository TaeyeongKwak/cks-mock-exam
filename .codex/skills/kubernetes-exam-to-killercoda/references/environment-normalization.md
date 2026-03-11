# Environment Normalization

Use this checklist when the source question assumes an environment that does not match the chosen Killercoda playground.

## Node And Host Mapping

- Rewrite host references to the real nodes in the scenario backend.
- For the standard two-node Kubernetes playground, use `controlplane` and `node01`.
- Replace variants such as `master`, `worker`, `node-01`, `node-1`, `control-plane`, or `cp` with the actual node names used by the scenario.
- Keep node names consistent across the prompt, manifests, helper scripts, and verification.

## Topology Reduction

- Compress tasks that casually mention extra nodes into the available topology when the exam objective stays intact.
- Keep anti-affinity, taint, and nodeSelector tasks meaningful by targeting the nodes that actually exist.
- Stop and call out a blocker only when the original task truly requires extra nodes or external clusters that cannot be emulated without changing the learning objective.

## Hidden Prerequisites

- Stage namespaces, sample manifests, vulnerable workloads, log files, certificates, or policies in bootstrap scripts when the question assumes they already exist.
- Preload images or artifacts when internet access during the learner step is uncertain.
- Create only the prerequisites. Do not apply the learner's final answer in bootstrap.

## Unsupported Platform Assumptions

- Replace cloud load balancer, DNS, IAM, or storage assumptions with local or in-cluster equivalents when the task objective allows it.
- Replace external reachability checks with local curl tests, test pods, or in-cluster probes.
- Replace vague host paths with directories that definitely exist, such as `/root`, `/tmp`, or paths created by bootstrap.

## Exam Fidelity

- Preserve the scored behavior even when the environment wording changes.
- Prefer equivalence over literal transcription. If the original wording would mislead the learner in Killercoda, rewrite it.
