# Labels

The skills speak in **roles**. This file maps each role to the actual label string in this repo's issue tracker. When a skill says "apply the `ready-for-agent` role", use the label in the second column.

Edit the "Label in this repo" column to match whatever vocabulary the tracker already uses.

## Category (one per issue)

| Role | Label in this repo | Meaning |
|---|---|---|
| `bug` | `bug` | something is broken |
| `enhancement` | `enhancement` | new feature or improvement |

## Triage state (one per issue)

| Role | Label in this repo | Meaning |
|---|---|---|
| `needs-triage` | `needs-triage` | waiting to be evaluated; how the Journal files things |
| `needs-info` | `needs-info` | waiting on the reporter for more information |
| `ready-for-agent` | `ready-for-agent` | fully specified, ready for an agent |
| `ready-for-human` | `ready-for-human` | requires human implementation |
| `wontfix` | `wontfix` | will not be actioned |

## Type

| Role | Label in this repo | Meaning |
|---|---|---|
| `spec` | `spec` | parent issue of a spec. Its tickets are its sub-issues. **Only a human closes it.** |

## Progress

| Role | Label in this repo | Meaning |
|---|---|---|
| `in-progress` | `in-progress` | an agent is implementing the ticket; no other agent should pick it up |
| `to-docs` | `to-docs` | every ticket of the spec has landed; its rules await documentation in `docs/features/` |

## Risk (one per ticket)

| Role | Label in this repo | Meaning |
|---|---|---|
| `risk:low` | `risk:low` | may land without a human when the gate passes |
| `risk:medium` | `risk:medium` | a human approves the merge |
| `risk:high` | `risk:high` | a human approves the merge; in-depth review |

How to classify risk: see `merge-gate.md`.
