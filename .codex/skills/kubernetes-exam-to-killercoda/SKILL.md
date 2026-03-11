---
name: kubernetes-exam-to-killercoda
description: Convert Kubernetes certification exam tasks and Korean-language requests to rewrite exam problems as Killercoda scenarios into Killercoda-compatible hands-on labs with bootstrap setup, environment normalization, and deterministic verification. Use when rewriting CKA, CKAD, or CKS style questions for Killercoda, adapting unsupported assumptions such as node names or topology, or generating scenario files like index.json, intro text, step markdown, background scripts, and verify.sh.
---

# Kubernetes Exam To Killercoda

## Overview

Convert exam-style Kubernetes tasks into runnable Killercoda labs. Produce a scenario that starts from a clean playground, prepares the prerequisite state, asks the learner to complete the task, and verifies the result without manual inspection.

## Workflow

### 1. Read the source task

- Extract the learner objective, expected end state, hidden prerequisites, and environment assumptions.
- Separate what the learner must do from what the scenario must preconfigure.
- Preserve the original exam intent and difficulty even when the environment wording changes.

### 2. Normalize to Killercoda

- Assume the default two-node Kubernetes playground unless the user names a different backend.
- Rewrite node names, shell prompts, file paths, host references, and cluster topology to match the actual playground.
- Prefer `controlplane` and `node01` for the standard Kubernetes playground. Rewrite variants such as `master`, `worker`, `node-01`, `node-1`, or `control-plane` into the real environment names.
- Replace unsupported or ambiguous infrastructure with an equivalent local or in-cluster setup.
- Move hidden dependencies into bootstrap scripts so the learner starts with a solvable environment.
- Read `references/environment-normalization.md` before finalizing the rewritten task.

### 3. Build the scenario package

- Default to a minimal package with `index.json`, `intro.md`, `finish.md`, per-step markdown, and `verify.sh`.
- Run environment-setup bootstrap scripts via `background.sh` (for example `intro/background.sh` or `stepN/background.sh`).
- Use a backend image that matches the task. Prefer `kubernetes-kubeadm-2nodes` for standard cluster exercises.
- Read `references/scenario-output.md` for the scenario file contract and minimal templates.

### 4. Write learner-facing instructions

- State the rewritten task in concise exam language.
- Name exact namespaces, resources, files, and nodes after normalization.
- Mention only the information the learner needs to solve the task.
- Avoid references to unavailable cloud consoles, SSH endpoints, hostnames, or infrastructure outside the playground.
- In every step `text.md`, append a collapsible answer key using HTML `<details><summary>...</summary>...</details>` so learners can open it only when needed.
- Build each answer key as a command set that configures a state passing that step's `verify.sh` checks.

### 5. Write deterministic verification

- Verify the final state rather than the command history unless the original requirement explicitly scores a file path or flag choice.
- Exit with a nonzero status on failure.
- Check every scored requirement: object existence, spec fields, labels, taints, scheduling, policy behavior, file content, or runtime behavior.
- Fail if the verification passes before the learner acts.
- Keep the check concise and robust enough to run on a clean playground.

### 6. Return the result

- Write the scenario files directly when working in a repository.
- Otherwise return the rewritten problem statement, the scenario tree, the file contents, and a short verification summary.

## Quality Bar

- Ensure the scenario is solvable on the declared Killercoda backend.
- Ensure bootstrap scripts create prerequisites without solving the learner task.
- Ensure verification fails before the solution and passes after the solution.
- Ensure naming is consistent across the prompt, bootstrap scripts, manifests, and verification.
- Ensure hidden dependencies such as manifests, images, sample workloads, or log files are staged during bootstrap instead of assumed.
- Ensure every step `text.md` includes a `<details>`-based answer key with runnable commands that pass the corresponding `verify.sh`.

## References

- Read `references/environment-normalization.md` when the source question mentions node names, hosts, topology, external dependencies, file paths, or platform assumptions that may not fit the playground.
- Read `references/scenario-output.md` when generating the scenario file tree, `index.json`, bootstrap scripts, or `verify.sh`.

## Example Rewrite

Source phrasing:

```text
SSH to node-01 and create a NetworkPolicy that only allows nginx pods in the prod namespace to receive traffic from pods with label access=granted.
```

Rewrite for the default playground:

```text
On `controlplane`, create a NetworkPolicy in namespace `prod` that allows ingress to pods labeled `app=nginx` only from pods labeled `access=granted`.
```

Bootstrap expectation:

- Create namespace `prod` if the source question assumes it exists.
- Create or stage sample `nginx` and client pods if the exercise needs traffic tests.
- Leave the policy itself for the learner.

Verification expectation:

- Confirm the policy exists in `prod`.
- Confirm the target pod selector is correct.
- Confirm only allowed traffic reaches the target workload.

Prefer explicit, runnable labs over literal but unsolved text transcription.
