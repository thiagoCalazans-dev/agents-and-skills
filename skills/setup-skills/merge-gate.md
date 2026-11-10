# Merge gate

What `merge-gate` checks before a merge without a human, and how to classify each ticket's risk. When in doubt, the gate calls the human.

The `merge-gate` script reads the **named code blocks** in this file (`checks`, `sensitive-paths`, `auto-merge-risk`, `marker`, `merge-method`). Edit the blocks' contents, but keep their names.

## Required checks

The exact names of the CI jobs that must be green on the PR's latest commit, one per line:

```checks
<job name>
```

## Sensitive paths

A PR touching any of these paths never lands without a human. One regular expression per line, matched against each file path in the diff from the repo root:

```sensitive-paths
^<migrations>/
^<auth>/
^<deploy>/
^\.github/
^\.claude/
^AGENTS\.md$
^CLAUDE\.md$
^docs/agents/
```

## Risk rule

The risk role is applied to the ticket when it is created, before implementation. The gate re-checks the paths against the real diff.

| Risk | When |
|---|---|
| `risk:high` | touches a sensitive path; changes data schema, auth, permissions, deploy, CI or the agents' rules; depends on a real external service |
| `risk:medium` | changes a feature's behaviour (a rule in `docs/features/` changes or is added) |
| `risk:low` | docs, copy, styles, or an additive change behind a flag that touches no existing rule |

When torn between two levels, use the higher one.

## Merge without a human

The risks that may land without a human when the gate passes, one label per line. Any other needs a human's approval.

```auto-merge-risk
risk:low
```

Merge method (`merge`, `squash` or `rebase`):

```merge-method
merge
```

## Reviewer verdict

`code-review` posts a PR comment starting with this marker, followed by the lines `Verdict: approve | request-changes`, `Commit: <sha>` and `Round: <n>/2`. The gate only accepts an `approve` verdict on the PR's latest commit.

```marker
<!-- REVIEWER-VERDICT -->
```
