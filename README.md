# Agents and skills

A workflow for a team of AI agents that takes a note about a product all the way to a merged PR: triage, spec, tickets, prototype, implementation, review, merge and feature docs.

The repo has two parts:

- **[`skills/`](skills/)**: the skills that do the work. They are generic: anything that changes from one project to another lives in the project's own `docs/agents/`, written once by `setup-skills`. Skills never mention agents; each one ends in a named result.
- **[`agents/`](agents/)**: one card per agent, for [Tucano](https://tucano.sh). A card says which skills the agent uses and what to do with each result, so the team layout can change without touching the skills.

## Install

```bash
git clone https://github.com/thiagoCalazans-dev/agents-and-skills.git
cd agents-and-skills
./install.sh
```

`install.sh` links every skill into `~/.claude/skills` and `~/.codex/skills` (or the folders you pass it). To update, run `git pull`. It never overwrites a skill folder that already exists.

## Set up a project

In the project, run the `setup-skills` skill once. It explores the repo, asks only what it can't find out and writes `docs/agents/`:

| File | Holds |
|---|---|
| `issue-tracker.md` | how to create, read and label issues and PRs |
| `labels.md` | the label for each role |
| `domain.md` | glossary, ADRs, feature rules, data model |
| `design.md` | the design system and the prototype convention |
| `commands.md` | main branch, dev, tests, lint, evidence level, ports |
| `merge-gate.md` | required checks, sensitive paths, risk rule |

It also points `AGENTS.md` at those files, and creates `CLAUDE.md` with a single `@AGENTS.md` line.

**Requirements for the full pipeline:** a GitHub repo, CI, and `gh` 2.94 or newer (for sub-issues and dependencies). `merge-gate` only works on GitHub. The other skills also work with GitLab or local Markdown issues, without the pipeline.

## Credits

Most skills are built on [mattpocock/skills](https://github.com/mattpocock/skills) (MIT). Some are used as they are, others are adapted, and a few are new; [skills/README.md](skills/README.md) says which. The `pr` skill also credits [Dex Horthy](https://github.com/dexhorthy) in its [CREDITS.md](skills/pr/CREDITS.md).

## License

[MIT](LICENSE).
