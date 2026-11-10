# Domain Docs

How the skills should consume this repo's domain documentation when exploring the codebase.

## Before exploring, read these

- **`GLOSSARY.md`** at the repo root, or **`GLOSSARY-MAP.md`** at the root if it exists: it points at one `GLOSSARY.md` per context. Read each one relevant to the topic.
- **`docs/adr/`**: ADRs that touch the area you're about to work in. In multi-context repos, also check `src/<context>/docs/adr/`.
- **`docs/features/<feature>.md`**: the current rules of each feature the change touches. They are the reference for what the system does today.
- **`docs/data-model.md`**, when the change touches data: tables, constraints and permissions.

<!-- If an existing document still does the job of docs/features (e.g. spec.md), record it here as the current source until it is migrated. -->

If any of these files don't exist, **proceed silently**. Don't flag their absence; don't suggest creating them upfront: `domain-modeling` creates the glossary and ADRs when a term or decision is resolved, and `to-docs` creates the feature rules when a spec is done.

## File structure

Single-context repo (most repos):

```
/
├── GLOSSARY.md
├── docs/
│   ├── adr/
│   │   └── 0001-event-sourced-orders.md
│   ├── features/
│   │   ├── auth.md
│   │   └── helpdesk.md
│   ├── data-model.md
│   └── research/
└── src/
```

Multi-context repo (`GLOSSARY-MAP.md` at the root): one `GLOSSARY.md` and one `docs/adr/` per context under `src/<context>/`, with `docs/adr/` at the root for system-wide decisions. `docs/features/` stays at the root.

## Use the glossary's vocabulary

When your output names a domain concept (an issue title, a refactor proposal, a hypothesis, a test name), use the term as defined in `GLOSSARY.md`. Don't drift to synonyms the glossary explicitly avoids.

If the concept you need isn't in the glossary yet, that's a signal: either you're inventing language the project doesn't use (reconsider) or there's a real gap (note it for `domain-modeling`).

## Flag conflicts

If your output contradicts an ADR or a rule in `docs/features/`, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0007 (event-sourced orders), but worth reopening because…_
>
> _Changes rule 3 of `docs/features/auth.md` (lock after 5 attempts): the spec asks for 3._

A feature rule that changes is a decision of the spec: record it among the implementation decisions, so `to-docs` updates the file afterwards.

## Research

`research` saves to `docs/research/<topic>.md`. The spec cites the research by pointer.
