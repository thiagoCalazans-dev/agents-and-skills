---
name: setup-skills
description: "Configure this repo for the agent workflow: issue tracker, labels, domain and feature docs, design, merge gate and commands. Run once before the other skills, and again to change the configuration."
disable-model-invocation: true
---

# Set up the skills

Scaffold the configuration the workflow's other skills read from `docs/agents/`. One file per topic, so each skill loads only what it uses:

| File | Topic | Read by |
|---|---|---|
| `issue-tracker.md` | where issues and PRs live, and the commands | all |
| `labels.md` | categories, states, type, progress and risk | `triage`, `to-spec`, `to-tickets`, `implement`, `chief-of-staff`, `merge-gate` |
| `domain.md` | glossary, ADRs, feature rules, data model | `grill-with-docs`, `domain-modeling`, `to-spec`, `to-tickets`, `implement`, `code-review`, `to-docs` |
| `design.md` | design system and prototypes | `prototype`, `to-tickets`, `code-review` |
| `commands.md` | main branch, dev, tests, lint, evidence, ports | `implement`, `chief-of-staff`, `merge-gate`, `prototype`, `to-docs`, `verify-app` |
| `merge-gate.md` | required checks, sensitive paths, risk rule | `to-tickets`, `code-review`, `merge-gate` |

This is a prompt-driven skill, not a deterministic script. Explore, present what you found, confirm with the user, then write.

## 1. Explore

Read whatever exists; don't assume:

- `git remote -v`: GitHub, GitLab, or no remote?
- Main branch: `git symbolic-ref --short refs/remotes/origin/HEAD` (or `gh repo view --json defaultBranchRef`).
- `AGENTS.md` and `CLAUDE.md` at the repo root: which exists? Is `CLAUDE.md` already just `@AGENTS.md`, or does it hold its own content? Is there already an `## Agent skills` block?
- `docs/agents/`: does this skill's output already exist? Then the job is updating what changed.
- Domain docs: `GLOSSARY.md`, `GLOSSARY-MAP.md`, the legacy `CONTEXT.md` / `CONTEXT-MAP.md` (offer to `git mv` them to their `GLOSSARY` name), `docs/adr/`, `docs/features/`, `docs/data-model.md`. Also look for documents already doing that job under another name, such as a `spec.md` holding business rules or a data-model document.
- Design: a `design.md`, tokens, `components.json` (shadcn), Tailwind config, a UI package. Is there a user interface? Without one, the Designer stays out.
- Commands: `Makefile`, `package.json` scripts, `justfile`, `docker-compose`. Note dev, tests, lint and generated-code check. Note fixed ports.
- Evidence: scripts that start the app in isolation and walk flows (Playwright, Cypress, an `e2e/` or `journeys/` folder), a repo-local `verify-app` skill.
- CI: the job names in `.github/workflows/` (or `.gitlab-ci.yml`). They are the gate's required checks.
- Sensitive areas: migrations, auth and permissions, deploy, CI, `.claude/`, `AGENTS.md`/`CLAUDE.md`, integrations with external services.
- Monorepo signals: `pnpm-workspace.yaml`, a `workspaces` field in `package.json`, `packages/*` with their own `src/`. Their absence means single-context, which is almost every repo.

Done when every row of the table above has a "found" or a "missing".

## 2. Present findings and ask

Summarise what's present and what's missing. Then take the sections in order: one section, one answer, then the next. Lead each section with the recommended answer so the user can accept it in a word. Skip a section exploration already settled.

**A. Issue tracker.** Propose the `git remote` host (GitHub or GitLab). With no remote, offer GitHub, GitLab, local markdown (`.scratch/`) or other (Jira, Linear…), described by the user in one paragraph. GitHub and GitLab need a reachable repo: with no remote, get the URL and wire it up before going further. Done when `gh repo view` / `glab repo view` prints the project.

**B. Labels.** Show the default list from [labels.md](labels.md) and ask one question: keep it? Collect overrides only when the tracker already uses other names for the same role, so existing labels are applied instead of duplicates created.

**C. Domain and feature docs.** Default to single-context (`GLOSSARY.md` + `docs/adr/` at the root): write it without asking. Offer multi-context only on monorepo signals. Propose the initial feature list (names only, drawn from the code's modules and existing docs) for `docs/features/`. When an existing document already holds business rules (a `spec.md`, say), record it in `domain.md` as the current source and tell the user that splitting it into `docs/features/` should become its own spec.

**D. Design.** Skip it when there is no UI. Confirm the design system's path found in exploration, or ask where it lives. Ask the screenshot sizes (desktop, mobile or both). The prototype convention is fixed: branch `prototype/<issue>`, with screenshots in `prototype-captures/` (see [design.md](design.md)).

**E. Commands.** Confirm the main branch and the commands found for dev, tests, lint and generated-code check. With fixed ports, the rule is one task at a time.

**F. Merge gate.** Confirm three things:
- the required checks, using the CI job names exactly;
- the sensitive paths, proposed from exploration as regular expressions;
- the default risk rule in [merge-gate.md](merge-gate.md).

**G. Evidence.** Ask the level, recommendation first:
- **No UI:** `none`. Tests are enough.
- **UI and flow scripts found:** `journeys`. Confirm the Start, Check, Run and Clean up commands, the evidence folder and the flow map. With no map, propose creating it later, in its own spec.
- **UI and no scripts:** `browser`. Confirm the Start command (the dev one will do if there is no isolated one), Clean up and the evidence folder. If it isn't in `.gitignore`, propose adding it.

Always ask how to sign in and set up test data without real data. Tell the user they can start at `browser` and move to `journeys` once a screen keeps breaking: changing the level is an edit to `commands.md`.

## 3. Confirm and edit

Show a draft of the `## Agent skills` block and of every `docs/agents/` file. Let the user edit before writing.

## 4. Write

**The file to edit is `AGENTS.md`.** It is the open standard read by Codex, OpenCode, Cursor and other agents. Claude Code reads `CLAUDE.md`, which imports `AGENTS.md` with a single `@AGENTS.md` line.

- **`AGENTS.md` exists:** edit it. If a `CLAUDE.md` with its own content also exists, propose moving that content into `AGENTS.md` and leaving only `@AGENTS.md` in `CLAUDE.md`. If `CLAUDE.md` doesn't exist, create it with that line.
- **Only `CLAUDE.md` exists:** propose the migration `git mv CLAUDE.md AGENTS.md` plus a new `CLAUDE.md` holding only `@AGENTS.md`. On the user's yes, migrate and edit `AGENTS.md`. Without it, edit `CLAUDE.md` and list the pending migration in the final summary.
- **Neither exists:** create `AGENTS.md`, and `CLAUDE.md` with `@AGENTS.md`.

Content lives in one place only: `AGENTS.md`. If an `## Agent skills` block already exists, update it in place and keep the user's edits to the surrounding sections.

**The block**, one line per file, pointers only:

```markdown
## Agent skills

Agent workflow configuration, one file per topic in `docs/agents/`:

- Issue tracker: [one-line summary]. `docs/agents/issue-tracker.md`
- Labels: [summary]. `docs/agents/labels.md`
- Domain and feature rules: [single-context or multi-context]. `docs/agents/domain.md`
- Design: [where the design system lives]. `docs/agents/design.md`
- Commands: [main branch, dev, tests, lint; evidence: level]. `docs/agents/commands.md`
- Merge gate: [checks and risk rule]. `docs/agents/merge-gate.md`
```

Drop the design line when there is no UI.

**The files** come from the seed templates in this folder, filled in with the answers:

- [issue-tracker-github.md](issue-tracker-github.md), [issue-tracker-gitlab.md](issue-tracker-gitlab.md) or [issue-tracker-local.md](issue-tracker-local.md). For any other tracker, write `issue-tracker.md` from the user's description.
- [labels.md](labels.md), [domain.md](domain.md), [design.md](design.md), [commands.md](commands.md), [merge-gate.md](merge-gate.md).

**The labels:** on GitHub or GitLab, create each configured label the tracker lacks (`gh label create` / `glab label create`).

Domain, feature and design documents are created lazily by the skills that write them. This skill writes only `docs/agents/` and the block.

## 5. Done

Tell the user the setup is complete and which skill reads each file (the table at the top). They can edit `docs/agents/*.md` directly later; re-running this skill is only needed to switch trackers or start from scratch.
