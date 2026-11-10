---
name: implement
description: Implement an issue-tracker ticket through to an open PR, or fix a PR the review sent back. Use when asked to implement a ticket by number, or to address a PR whose verdict requests changes.
---

# Implement

You start with a fresh context. Everything you need is in the repo and the tracker.

First, read the configuration in `docs/agents/`: `issue-tracker.md`, `labels.md`, `commands.md` and `merge-gate.md`. "Main branch" in this skill means the one in the `main-branch` block of `commands.md`. If `docs/agents/` doesn't exist, tell the user to run `setup-skills` and stop.

Two modes:

- **New**: you got a ticket number. Follow steps 1 to 5.
- **Fix**: you got the number of a PR whose verdict is `request-changes`. Go to "Fix mode".

## 1. Prepare

1. Check the working tree is clean (`git status --short`). With uncommitted changes, end in `blocked`.
2. Update from the remote: `git fetch origin`. Work from `origin/<main branch>`, never by switching to the main branch itself: in a `git worktree` it may be checked out in another folder.
3. Read the ticket and check:
   - it is open and has the `ready-for-agent` role;
   - it doesn't have the `in-progress` role;
   - every blocker is closed;
   - the parent spec, if any, exists.

   If any check fails, end in `blocked` with the reason.
4. Create branch `ticket/<NN>-<short-name>` with `git switch -c <branch> origin/<main branch>` (lowercase, no accents, from the title). If it already exists, end in `blocked`.
5. Apply the `in-progress` role to the ticket. Don't edit the ticket's title or body.

Done when the branch exists and the ticket is `in-progress`.

## 2. Load context

Read only what the ticket needs, but reading less never waives a rule: when in doubt, read more.

1. **Always:** `AGENTS.md`, the whole ticket (its `Read` section and acceptance criteria), the parent spec, and `CODING_STANDARDS.md` if it exists.
2. **Pointers:** the files and sections in the ticket's `Read` section. They are the starting point, not the limit.
3. **Domain:** follow `docs/agents/domain.md`: the `docs/features/` rules of the features touched, glossary terms, ADRs and the area's data model.
4. **UI:** `docs/agents/design.md` and the approved screenshots in the ticket's `Design` section. They are the expected result.
5. **Code:** use a similar feature as a model and follow its patterns. Read signatures before bodies. Before changing a function or a query, find its callers.

Done when you can say, for every acceptance criterion, where in the code it will be met.

## 3. Implement

- Ticket with the `bug` role: use the `diagnosing-bugs` skill. Any other: use the `tdd` skill, at the test seams the spec set.
- **Strict scope:** only what the ticket asks for. Improvements you notice go in the PR's "Out of scope" section, not in the code.
- **Uncovered case:** if the spec and docs don't cover a situation you need, or contradict each other, end in `blocked` with the question. Search the docs for the term first (`grep`), since you haven't read them all.
- **New library or schema change:** only as the repo's docs prescribe. If they say nothing, end in `blocked`.
- **Commits:** small, coherent, in the repo's convention.

## 4. Validate

1. Run the lint, tests and other checks in `commands.md`. Everything must pass, without disabling rules or skipping tests. When filtering output, start the command with `set -o pipefail`.
2. Walk every acceptance criterion and record its evidence: the test, the command and its output.
3. **Evidence:** if the ticket has UI or the risk is `risk:medium` or `risk:high`, use the `verify-app` skill. On `failed`, fix and verify again; a flow you can't get to pass goes into the PR as "not verified". With `risk:low` and no UI, skip it.

Done when every criterion has evidence, or is listed as "not verifiable" with the reason.

## 5. Open the PR

1. Push the branch: `git push -u origin <branch>`.
2. Open the PR against the main branch with the ticket's title. Write the body with the `pr` skill. The **first line** is `Closes #<ticket>`, and it closes no other issue. Also include:
   - each acceptance criterion with its evidence;
   - what was read and what was left out;
   - decisions made and docs changed;
   - what couldn't be verified;
   - an "Out of scope" section with suggestions.
3. If `verify-app` ran, publish the evidence to the PR through its phase 6.
4. If `commands.md` has a "Manual testing" section and the ticket's risk is **not** in `auto-merge-risk` (`merge-gate.md`), leave the environment ready as it describes. When the merge depends on a human, they test; when it doesn't, skip this step.

End in `PR opened #<PR>`.

## Fix mode

1. Read the PR's latest verdict, the comment carrying the marker from `merge-gate.md`. Check the verdict is `request-changes` and covers the latest commit. If it doesn't, end in `blocked`.
2. Check out the PR branch and update it. If the main branch has moved on, bring it in with `git merge origin/<main branch>`.
3. Fix the verdict's findings, and only those. If you disagree with a finding, reply on the PR with the reason instead of changing the code.
4. Validate as in step 4 and push the commits.
5. Comment on the PR what changed, finding by finding.

End in `PR updated #<PR>`.

## Output

The last line of the reply is **exactly one** of these results:

| Result | What the tracker holds |
|---|---|
| `PR opened #<PR>` | PR with `Closes #<ticket>`; ticket `in-progress` |
| `PR updated #<PR>` | new commits and one comment per finding |
| `blocked #<ticket or PR>: <reason>` | the question commented on the ticket or PR; the ticket leaves `in-progress` and `ready-for-agent` and moves to `needs-info`, so it isn't picked up again before the answer |

This skill doesn't review its own work, doesn't merge and doesn't call anyone: the next step belongs to whoever invoked it.
