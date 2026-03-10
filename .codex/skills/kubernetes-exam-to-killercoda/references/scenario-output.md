# Scenario Output

Use this file when generating a Killercoda scenario package.

## Minimal File Tree

```text
scenario-name/
  index.json
  intro.md
  finish.md
  step1/
    text.md
    verify.sh
```

Add `foreground.sh` or `background.sh` only when the scenario needs bootstrap work during `intro` or a specific step.

## Minimal `index.json`

```json
{
  "title": "Scenario Title",
  "description": "Short summary of the lab",
  "details": {
    "intro": {
      "text": "intro.md"
    },
    "steps": [
      {
        "title": "Solve the task",
        "text": "step1/text.md",
        "verify": "step1/verify.sh"
      }
    ],
    "finish": {
      "text": "finish.md"
    }
  },
  "backend": {
    "imageid": "kubernetes-kubeadm-2nodes"
  }
}
```

This layout matches the public Killercoda scenario examples for Kubernetes labs.

## Content Rules

- Write `intro.md` for context, prerequisites, and any non-secret setup notes.
- Write `step1/text.md` as the learner-facing exam prompt.
- Write `finish.md` as a short completion message and optional recap.
- Write `verify.sh` as a deterministic shell script that exits nonzero on failure.

## Bootstrap Placement

- Put environment preparation in `intro/background.sh`, `intro/foreground.sh`, or a step-level script when asynchronous setup is needed.
- Keep bootstrap idempotent where practical.
- Avoid long-running setup inside `verify.sh`.

## Verification Rules

- Check the exact scored state.
- Print concise output that helps diagnose failures.
- Fail before learner action on a clean environment.
- Avoid brittle checks on timestamps, ordering, or unrelated metadata unless the task explicitly requires them.
