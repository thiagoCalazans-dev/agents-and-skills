---
name: to-spec
description: "Turn the current conversation into a spec and publish it to the issue tracker as a parent issue (`spec` role). No interview: just synthesis of what's already been discussed. Use when an interview or a plan is done and needs to become a spec."
---

This skill takes the current conversation context and codebase understanding and produces a spec. **Do NOT interview the user again**: synthesise what you already know.

Read the configuration in `docs/agents/`: `issue-tracker.md`, `labels.md` and `domain.md`. Without it, tell the user to run `setup-skills` and stop.

## Process

1. **Explore the repo**, if you haven't already. Following `docs/agents/domain.md`, read the `docs/features/` rules of the features touched, the glossary terms and the area's ADRs. Use the glossary's vocabulary throughout the spec, and respect the ADRs.

2. **Check against the current rules.** List every `docs/features/` rule the spec creates, changes or removes. A current rule that changes is a decision: it goes under "Implementation decisions" with the old rule's number. If the conversation didn't settle a contradiction, end in `spec needs you` with the question.

3. **Sketch the test seams.** Prefer existing seams and use the highest one possible. If new seams are needed, propose them at the highest point you can. The fewer seams across the codebase, the better; the ideal number is one.

   Check with the user that these seams match their expectations.

4. **Write the spec** using the template below and publish it to the issue tracker with the `spec` role and the category (`enhancement` or `bug`). Don't apply `ready-for-agent`: the spec is the parent issue, and its tickets are what becomes agent work.

5. **Close the source issues.** For each issue in the conversation that led to the spec (the `needs-triage` ones filed earlier), comment "became spec #<spec>" and close it. The spec lists them all under "Source".

<spec-template>

## Source

The issues that led to this spec (#12, #15), or "direct conversation".

## Problem Statement

The problem that the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

A LONG, numbered list of user stories, each in the format:

1. As an <actor>, I want a <feature>, so that <benefit>

<user-story-example>
1. As a mobile bank customer, I want to see balance on my accounts, so that I can make better informed decisions about my spending
</user-story-example>

This list should be extremely extensive and cover all aspects of the feature.

## Implementation Decisions

The decisions that were made, for example:

- the modules that will be built or modified;
- the interfaces of those modules that change;
- technical clarifications from the developer;
- architectural decisions;
- schema changes;
- API contracts;
- specific interactions;
- **feature rules that change:** "Rule 3 of `docs/features/auth.md` (lock after 5 attempts) becomes 3 attempts".

Do NOT include specific file paths or code snippets: they go stale fast.

Exception: if a prototype produced a snippet that encodes a decision more precisely than prose (state machine, reducer, schema, type shape), inline it within the relevant decision and note that it came from a prototype. Trim it to the decision-rich parts.

## Testing Decisions

- What makes a good test: only test external behaviour, not implementation details.
- Which modules will be tested.
- Prior art for the tests: similar tests already in the codebase.

## Out of Scope

What is out of scope for this spec.

## Docs to Update

The `docs/features/` files that need to be created or updated once the spec is done, each with the rules affected. It is `to-docs`' work list.

## Further Notes

Any further notes about the feature.

</spec-template>

## Output

The last line of the reply is **exactly one** of these results:

| Result | What the tracker holds |
|---|---|
| `spec published #<spec>` | an issue with the `spec` role and the category; the source issues closed, pointing at it |
| `spec needs you: <question>` | nothing; the question goes in the reply |

This skill doesn't break the spec into tickets and doesn't call anyone: the next step belongs to whoever invoked it.
