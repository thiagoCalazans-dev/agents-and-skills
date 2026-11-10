---
name: journal
description: File notes about the product as issues for triage, in the note-taker's own words, without planning anything. Use when someone reports a problem, a bug or an improvement idea for the product, to keep and triage later.
---

# Journal

File what the person ran into (bugs, annoyances, product improvement ideas) as issues for triage. **You file, you don't plan:** no solution, priority or estimate.

Read the repo's `docs/agents/issue-tracker.md` and `docs/agents/labels.md`. If you don't have the repo, read those files through the tracker's connector. Without them, tell the user to run `setup-skills` and stop.

## 1. Split the topics

Split the message into topics, one per problem or idea. A message with three topics becomes three issues.

For each topic, decide:

- **About the product?** Something that can become work in this repo: a defect, a behaviour, a screen, a rule. Anything that isn't ("research supplier X", "call customer Y") doesn't become an issue: hand it back in the reply, saying it isn't for this repo.
- **Category:** `bug` if something is broken or differs from what's expected; `enhancement` if it's something new or an improvement.

## 2. Look for a duplicate

Search the open issues by title and by two or three keywords of the topic. If an issue already covers the same topic, **comment on it** with the new note instead of creating another.

## 3. File

For each new topic, create an issue:

- **Title:** short and descriptive, in the terms the person used.
- **Roles:** `needs-triage` and the category.
- **Body:**

```markdown
## Note

<the note-taker's words, without rewriting the meaning>

## Context

<whatever came with it: link, screenshot, screen, time, steps; or "none">
```

Fix only typos that get in the way of reading. Add no guessed cause, solution or priority: that belongs to triage.

## Output

The last line of the reply is **exactly one** of these results, covering every topic of the message:

| Result | What the tracker holds |
|---|---|
| `filed #A, #B…` | new issues with `needs-triage` and a category; comments on duplicates found, listed as `(already existed #C)` |
| `nothing to file: <reason>` | nothing; e.g. no topic was about the product |

This skill doesn't triage, plan or call anyone: the next step belongs to whoever invoked it.
