---
name: to-docs
description: Maintain docs/features/<feature>.md with each feature's current rules in plain language. Updates them from a finished spec, or migrates rules written in another format. Opens a docs PR. Use when a spec is done (to-docs role) or to migrate an existing rules document.
---

# To docs

Maintain `docs/features/<feature>.md`: **the rules each feature follows today, in plain language**, so anyone can understand the system and plan changes without reading code. You write **what the system does**, not how the code does it.

Read the configuration in `docs/agents/`: `issue-tracker.md`, `labels.md`, `domain.md` and the `main-branch` block of `commands.md`. Without it, tell the user to run `setup-skills` and stop.

Two modes:

- **Spec done:** you got a spec with the `to-docs` role. Follow steps 1 to 4.
- **Migrate:** you got a rules document in another format (e.g. a `spec.md`). Go to "Migrate mode".

## Format of a feature file

```markdown
# <Feature>

<2–3 sentence summary: what it's for and who uses it.>

## Rules

1. <Rule in plain language.>
   _Source: spec #12, PR #34. In force since 2026-11-08._
2. ...

## Out of scope / known limits

- ...

## Related

- Glossary: <terms>. ADRs: <numbers>. Data model: <tables>.

## History

- 2026-11-08: rule 3 said "<old text>"; changed by spec #12.
```

- **One rule, one or two sentences**, in the glossary's terms. No file paths or function names, except under "Related".
- **Stable numbers:** a new rule gets the next free number, and numbers are never reused. A removed rule leaves "Rules" and goes to "History" as "removed".
- **Every rule cites its source and date.** When it changes, the old text goes to "History"; nothing is deleted without a record.
- **One file per feature,** with short names (`auth.md`, `support.md`). A rule spanning several features lives in the one that owns it, and the others point there.

## 1. Gather what landed

1. Read the spec: the body (especially "Implementation Decisions" and "Docs to Update") and the comments.
2. List the spec's tickets and the PRs that closed them. Read the diffs **only to confirm** what actually landed.
3. Read the `docs/features/*.md` files cited and `GLOSSARY.md`.

## 2. Write

1. Create branch `docs/spec-<number>` from an updated main branch.
2. For each feature in "Docs to Update", create or update the file: new rules, changed rules (with the old text in "History") and removed rules.
3. If the spec brought new terms or a technical decision worth an ADR, use the `domain-modeling` skill for the glossary and ADRs.
4. **Divergence:** if a merged diff does something other than what the spec says, document what **landed** and record the difference in the PR. Don't pick on your own which one is right.

## 3. Check

- Every spec decision that changes behaviour shows up in some rule.
- Every new or changed rule cites `spec #<n>` and at least one PR.
- Reread each file as someone who doesn't know the code: can you tell what the system does?

## 4. Open the PR

1. Push the branch and open the PR against the main branch: title "docs: rules from spec #<n>", body listing the rules created, changed and removed per file, plus a "Divergences" section if any.
2. Comment the PR link on the spec.

**Don't close the spec and don't merge:** both belong to the human.

## Migrate mode

1. Read the whole old document and `docs/agents/domain.md`.
2. Group the rules by feature, following the old document's headings and the code's modules.
3. Check each rule against the code: does it still hold? A rule the code doesn't follow goes to the PR's "Divergences" section, not into the rules.
4. Write the files in the format above, with the source "migrated from `<document>`" and today's date. "History" starts empty.
5. In `docs/agents/domain.md`, replace the note pointing to the old document as the current source with `docs/features/`.
6. Open the PR on branch `docs/migrate-<document>`, with the table "old document section → feature file" and the divergences. Don't delete the old document: say in the PR that deleting it is the human's call.

## Output

The last line of the reply is **exactly one** of these results:

| Result | What the tracker holds |
|---|---|
| `docs ready PR #<PR>` | a docs PR; its link commented on the spec |
| `docs ready PR #<PR>; divergences` | the same, with a "Divergences" section asking for the human's decision |
| `migration ready PR #<PR>` | a PR with the initial `docs/features/*.md` |
| `nothing to document #<spec>: <reason>` | a comment on the spec; e.g. the spec changed no rule |

This skill doesn't close the spec, doesn't merge and doesn't call anyone: the next step belongs to whoever invoked it.
