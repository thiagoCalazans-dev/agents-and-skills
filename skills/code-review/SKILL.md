---
name: code-review
description: "Review a PR, or the changes since a fixed point (commit, branch, tag), along two axes: Standards (does it follow the repo's documented standards?) and Spec (does it do what the ticket and spec asked?). Depth follows risk. On a PR, it posts the verdict there. Use to review a PR, a branch, work in progress, or \"since X\"."
---

Two-axis review:

- **Standards**: does the code follow this repo's documented standards?
- **Spec**: does the code faithfully do what the ticket and spec asked for?

The axes stay separate because one can pass while the other fails: spotless code that does the wrong thing, or code that does what was asked but breaks the conventions. Reviewing both together lets one hide the other.

Read the configuration in `docs/agents/` if it exists: `issue-tracker.md`, `labels.md`, `domain.md` and `merge-gate.md`.

## 1. Pin the target

- **PR:** the PR is the target. Note its head commit (`headRefOid`); the fixed point is the PR's base. Check whether one of your verdicts is already there, the comment carrying the marker from `merge-gate.md`:
  - **First review:** the diff is `git diff <base>...<head>`.
  - **Re-review:** the diff is only the new part, `git diff <commit of the last verdict>..<head>`. The round is the number of earlier `request-changes` verdicts plus one.
- **No PR:** the fixed point is whatever the user said (SHA, branch, tag, `main`, `HEAD~5`…). If they didn't say, ask. The diff is `git diff <fixed point>...HEAD`.

Confirm the fixed point resolves (`git rev-parse`) and the diff is non-empty. A bad target should fail here, not inside two sub-agents.

## 2. Gather the sources

**Spec:** look in this order and use every one that exists:

1. the ticket the PR closes (`Closes #N`) or the commits reference;
2. the ticket's parent spec;
3. the `docs/features/` rules of the features touched, following `docs/agents/domain.md`;
4. the `verify-app` evidence on the PR: read the summary (the flow table, what wasn't proved and the log errors). Open the screenshots only when the ticket has a `Design` section, to compare them with the approved ones.

With none, the Spec axis is skipped and the verdict says "no spec available".

**Standards:** every file documenting how code should be written: `CODING_STANDARDS.md`, `CONTRIBUTING.md` and the rules in `AGENTS.md`. Plus the **smell baseline** below, which applies even when the repo documents nothing:

- **The repo overrides.** A documented repo standard always wins; where it endorses something the baseline would flag, suppress the smell.
- **Always a judgement call.** Each smell is a labelled heuristic ("possible Feature Envy"), never a hard violation. Skip anything tooling already enforces.

Baseline (Fowler, _Refactoring_, ch. 3). Each reads what it is → how to fix:

- **Mysterious Name**: a name that doesn't reveal what the thing does or holds. → rename it; if no honest name comes, the design's murky.
- **Duplicated Code**: the same logic shape appears in more than one hunk of the change. → extract the shared shape.
- **Feature Envy**: a method reaching into another object's data more than its own. → move the method onto the data.
- **Data Clumps**: the same fields or params keep travelling together. → bundle them into one type.
- **Primitive Obsession**: a primitive or string standing in for a domain concept. → give the concept its own type.
- **Repeated Switches**: the same `switch`/`if`-cascade on the same type recurs. → polymorphism, or one shared map.
- **Shotgun Surgery**: one logical change scatters edits across many files. → gather what changes together into one module.
- **Divergent Change**: one file is edited for several unrelated reasons. → split, one reason per module.
- **Speculative Generality**: abstraction, params or hooks for needs the spec doesn't have. → delete until a real need shows.
- **Message Chains**: long `a.b().c().d()` navigation. → hide the walk behind one method on the first object.
- **Middle Man**: a class or function that mostly delegates. → call the real target directly.
- **Refused Bequest**: a subclass ignoring most of what it inherits. → replace inheritance with composition.

## 3. Review at the depth of the risk

Read the ticket's risk role (`labels.md`):

- **`risk:low`:** a single pass, both axes in one context, on your own model. Still write the two reports separately.
- **`risk:medium`, `risk:high` or no risk:** two sub-agents in parallel, each with a fresh context, and you aggregate the reports they return:
  - **Spec:** the strongest model available, at high effort. It is the judgement axis.
  - **Standards:** a mid-tier model, at medium effort. It is the more mechanical axis.

**Standards sub-agent prompt:**
- the diff command and commit list;
- the standards files found and **the baseline pasted in full** (it has no other access to it);
- the brief: "Report, per file/hunk, (a) every violation of a documented standard, citing the file and the rule; (b) every baseline smell, naming it and quoting the hunk. Separate hard violations from judgement calls: documented standards can be hard, smells are always judgement calls, and a repo standard overrides the baseline. Skip anything tooling enforces. Under 400 words."

**Spec sub-agent prompt:**
- the diff command, commit list and spec sources (contents or paths);
- the brief: "Report (a) requirements asked for that are missing or partial; (b) behaviour in the diff that wasn't asked for (scope creep); (c) requirements that look implemented but wrongly; (d) acceptance criteria whose evidence on the PR doesn't show what they ask. Quote the spec line for each finding. Under 400 words."

On a re-review, both also get the findings already posted, told not to repeat them and to check whether they were resolved.

## 4. Decide the verdict

Present the reports under `## Standards` and `## Spec`, verbatim or lightly cleaned. **Don't merge or rerank findings across axes.** End with one line: the total findings per axis and the worst within each.

- **`request-changes`** on any hard violation of a documented standard, any Spec finding of type (a), (c) or (d), or scope creep (b) that changes behaviour.
- **`approve`** otherwise. Smells and suggestions go in the verdict but never send the PR back on their own.
- A mechanical finding that recurs across PRs is noted as a "lint-rule candidate", for `retro`.

## 5. Post the verdict

**On a PR**, comment on it:

```
<marker from merge-gate.md>
Verdict: approve | request-changes
Commit: <reviewed head sha>
Round: <n>/2

## Standards
...
## Spec
...
```

**Without a PR**, just reply with the reports and the verdict.

## Output

The last line of the reply is **exactly one** of these results:

| Result | What the PR holds |
|---|---|
| `approved PR #<PR>` | verdict `approve` on the latest commit |
| `changes requested PR #<PR> (<n>/2)` | verdict `request-changes` |
| `rounds exhausted PR #<PR>` | a third round would still send it back: `request-changes` with "Round: 3/2", asking for a human |
| `reviewed` | no PR: the reports in the reply |

This skill doesn't fix the code, doesn't merge and doesn't call anyone: the next step belongs to whoever invoked it.
