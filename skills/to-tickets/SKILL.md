---
name: to-tickets
description: Break a spec, a plan or the conversation into tracer-bullet tickets, with blocking edges, risk and reading pointers, published as sub-issues on the tracker. Also releases a ticket that was waiting for design once its prototype is approved. Use to break a spec into tickets, or to release a ticket whose design was approved.
---

# To tickets

Break the work into **tickets**: tracer-bullet vertical slices, each declaring the tickets that **block** it. Each ticket will be implemented by another session, starting fresh, that knows only what is in the repo and the tracker. Nothing can live only in this conversation.

Read the configuration in `docs/agents/`: `issue-tracker.md`, `labels.md`, `domain.md`, `design.md` and `merge-gate.md`. Without it, tell the user to run `setup-skills` and stop.

Two modes:

- **Break down:** you got a spec (number), a plan, or the conversation. Follow steps 1 to 6.
- **Release:** you got a ticket that was waiting for design. Go to "Release mode".

## 1. Gather context

1. Read the whole spec, body and comments. Without a spec, use the plan or the conversation.
2. Read `AGENTS.md` and, following `docs/agents/domain.md`, the `docs/features/` rules, glossary terms and ADRs of the areas touched. Use the glossary's vocabulary in titles and descriptions.
3. List the tracker's open tickets, so you neither repeat nor contradict what's already planned.
4. Explore the code of the areas touched: what already exists, a similar feature to use as a model, and chances to **prefactor**. "Make the change easy, then make the easy change."

## 2. Slice

Break the work into **tracer-bullet** tickets:

- Each slice cuts a narrow but **complete** path through every layer (schema, API, UI, tests): vertical, not a horizontal slice of one layer.
- A finished slice is demoable or verifiable on its own.
- Each slice fits in a single fresh context window.
- Prefactoring comes first.

Give each ticket its **blocking edges**: the tickets that must finish before it can start. A ticket with no blockers can start right away.

**Wide refactors are the exception.** A mechanical change (rename a column, retype a shared symbol) whose **blast radius** fans across the whole codebase can't fit in one slice that lands green. Sequence it as **expand–contract**:
- **Expand:** add the new form beside the old.
- **Migrate:** move the callers in batches sized by blast radius, one ticket per batch, each blocked by the expand.
- **Contract:** delete the old form, in a ticket blocked by every batch.

## 3. Write each ticket

For each ticket, decide:

- **Title:** short, in the glossary's terms.
- **What to build:** the end-to-end behaviour, from the user's point of view, not a list of layers.
- **Acceptance criteria:** verifiable results. Every new or changed rule has a test covering it. Anything depending on a human or a real external service is stated explicitly.
- **New journey:** only when the project uses the `journeys` evidence level (`commands.md`) and the ticket creates a flow the flow map doesn't have. Add the line `New journey: <flow name>` to `Read`. Without it, verification uses a provisional journey, which is cheaper.
- **Read:** the pointers that make implementation cheap, such as doc sections by exact title (`docs/features/auth.md › Rule 3`), starting files, test files and a similar feature as a model. Tickets are short-lived, so file paths belong here. Code doesn't, unless a prototype produced a snippet that encodes a decision better than prose.
- **Risk:** by the rule in `merge-gate.md`. When torn, the higher level.
- **Design:** if the ticket has a new screen or a layout change and the project has a `design.md`, the ticket **waits for design**.
- **Category:** the spec's (`enhancement` or `bug`).

Ticket body:

```markdown
## Spec

#<spec>

## What to build

<end-to-end behaviour>

## Acceptance criteria

- [ ] <criterion>

## Read

- <doc › section>; code: `<file>`
- New journey: <flow name> (only when needed)

## Design

Waiting for prototype.
```

The `## Design` section exists only on tickets waiting for design. Blocking goes in as the tracker's native dependencies; where there are none, a `## Blocked by` section.

## 4. Check

1. **Coverage:** build the table "spec user story or decision → ticket(s)". Every user story and every implementation decision needs at least one ticket. If any is left over, create the missing ticket; if it shouldn't be built, end in `incomplete coverage` with the list, because only the spec's author can change the spec.
2. **Pointers:** every file on the "Read" line exists, and every section cited shows up in `grep -n '^#' <doc>`. Files the ticket itself will create stay off that line.
3. **Self-sufficiency:** reread each ticket as someone who hasn't seen this conversation. Can it be implemented without asking anything?
4. **Order:** blockers come before what they block.

Done when the coverage table has no empty row and all four checks pass.

## 5. Confirm the breakdown (only when needed)

Show the breakdown to the user (titles, blockers and what each ticket delivers) and iterate until they approve **only** when a ticket is `risk:high` or the user asked to see it first. Otherwise publish directly: the spec has already been through an interview.

## 6. Publish

1. Create the tickets in dependency order (blockers first), each as a **sub-issue of the spec**, with native dependencies, the category and the risk role.
2. Tickets not waiting for design get the `ready-for-agent` role. Those waiting for design don't.
3. Comment on the spec with the coverage table and the ticket list (number, title, blockers, risk).

Don't close or change the spec beyond that comment.

## Release mode

1. Read the ticket and its comments. Check the prototype was approved: a `prototype` comment with the approved version, the screenshots and the branch link. Without approval, end in `waiting for design`.
2. Replace the text of the ticket's `## Design` section with the prototype branch link and the approved screenshots.
3. Apply the `ready-for-agent` role.

## Output

The last line of the reply is **exactly one** of these results:

| Result | What the tracker holds |
|---|---|
| `tickets published #A, #B…` | sub-issues of the spec, all `ready-for-agent` |
| `tickets published #A, #B…; need design #C, #D…` | sub-issues of the spec; those waiting for design lack `ready-for-agent` |
| `ticket released #<ticket>` | ticket with the design attached and `ready-for-agent` |
| `waiting for design #<ticket>` | nothing |
| `incomplete coverage #<spec>: <user stories>` | nothing published; the list goes in the reply |

This skill doesn't implement, doesn't prototype and doesn't call anyone: the next step belongs to whoever invoked it.
