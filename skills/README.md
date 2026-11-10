# Skills

Run [`setup-skills`](setup-skills/SKILL.md) once per project before the others.

## Planning

| Skill | What it does | Origin |
|---|---|---|
| [journal](journal/SKILL.md) | files notes about the product as issues for triage | new |
| [triage](triage/SKILL.md) | moves issues through the triage states | Matt Pocock |
| [grill-with-docs](grill-with-docs/SKILL.md) | interviews you about a plan, updating the glossary and ADRs | Matt Pocock |
| [grilling](grilling/SKILL.md) | the interview loop on its own | Matt Pocock |
| [domain-modeling](domain-modeling/SKILL.md) | keeps `GLOSSARY.md` and the ADRs | Matt Pocock |
| [research](research/SKILL.md) | researches a question against primary sources | Matt Pocock |
| [to-spec](to-spec/SKILL.md) | turns the conversation into a spec issue | adapted from Matt Pocock |
| [to-tickets](to-tickets/SKILL.md) | breaks a spec into tickets with risk and reading pointers | adapted from Matt Pocock |
| [prototype](prototype/SKILL.md) | prototypes a ticket's screen for approval, or a piece of logic | adapted from Matt Pocock |

## Pipeline

| Skill | What it does | Origin |
|---|---|---|
| [chief-of-staff](chief-of-staff/SKILL.md) | reads the tracker and decides the next step | adapted from Matt Pocock |
| [implement](implement/SKILL.md) | implements a ticket through to a PR, or fixes a PR sent back | adapted from Matt Pocock |
| [tdd](tdd/SKILL.md) | test-first, one vertical slice at a time | Matt Pocock |
| [diagnosing-bugs](diagnosing-bugs/SKILL.md) | diagnosis loop for hard bugs | Matt Pocock |
| [verify-app](verify-app/SKILL.md) | proves a change in the running app, with screenshots | new |
| [pr](pr/SKILL.md) | writes the PR body | Matt Pocock |
| [code-review](code-review/SKILL.md) | reviews standards and spec, with depth by risk, and records a verdict | adapted from Matt Pocock |
| [merge-gate](merge-gate/SKILL.md) | decides whether a PR can land without a human, and merges it | new |
| [to-docs](to-docs/SKILL.md) | keeps each feature's rules in `docs/features/` | new |

## Support

| Skill | What it does | Origin |
|---|---|---|
| [setup-skills](setup-skills/SKILL.md) | configures a project for these skills | adapted from Matt Pocock |
| [retro](retro/SKILL.md) | retrospective that turns friction into fixes | Matt Pocock |
| [handoff](handoff/SKILL.md) | hands a long session over to a fresh one | Matt Pocock |
| [writing-for-agents](writing-for-agents/SKILL.md) | guide for writing skills and `AGENTS.md` | Matt Pocock |

"Matt Pocock" means taken from [mattpocock/skills@4ae2317](https://github.com/mattpocock/skills/tree/4ae2317ddb22b046e26455e4f9c9b3aaaf62212d). The only change to those is in `triage`, which points at `setup-skills` instead of `setup-matt-pocock-skills`.
