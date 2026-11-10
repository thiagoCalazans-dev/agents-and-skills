---
name: prototype
description: Build a prototype to answer a design question. It can be the expected screen of a ticket, with variants, screenshots and human approval, or an HTML file that lets anyone drive a piece of logic or a state machine. Use to prototype a ticket's screen, explore what something should look like, or feel out whether a state model is right.
---

# Prototype

A prototype is **throwaway code that answers a question**. The question decides the shape.

## Pick a branch

- **"What should this screen look like?"** (including the screen of a ticket waiting for design) → [UI.md](UI.md). Versions of the screen inside the app, switchable by a URL param, with screenshots for approval.
- **"Is this logic or state model right?"** → [LOGIC.md](LOGIC.md). A single HTML file anyone can open and click through.

The two branches produce very different artifacts; picking the wrong one wastes the whole prototype. If the question is ambiguous and the user isn't around, pick by the surrounding code (a backend module → logic; a page or component → UI) and state the assumption at the top of the prototype.

## Rules for both branches

1. **Throwaway from day one, and marked as such.** The prototype sits close to where it will be used, named so it's obviously a prototype. Throwaway routes follow the project's existing routing convention.
2. **Trivial to run.** UI starts from one project command (the "UI prototype" in `docs/agents/commands.md`, when present). Logic is an HTML file opened by double-click.
3. **No persistence.** State lives in memory. If the question involves a database, use a scratch one named "PROTOTYPE, wipe me".
4. **Skip the polish.** No tests, no error handling beyond what makes it run, no abstractions.
5. **Surface the state.** After every action (logic) or variant switch (UI), show the full relevant state.
6. **Keep it out of the main branch** (the one in `docs/agents/commands.md`). The prototype is committed to branch `prototype/<issue number>` (or `prototype/<name>` without an issue), never to the main branch. The main branch gets only the validated decision, and the implementation carries it there, not this skill. Leave a pointer to the branch on the issue, with the answer: the verdict and the question it settled.

## Output

The last line of the reply is **exactly one** of these results:

| Result | What the tracker holds |
|---|---|
| `waiting for approval #<ticket>` | a ticket comment with the branch and the versions' screenshots |
| `prototype approved #<ticket>` | a ticket comment with the approved version, its screenshots and the branch link |
| `prototype rejected #<ticket>: <reason>` | a comment with the reason |
| `logic prototype ready: <branch or file>` | a pointer on the issue, if there is one |

This skill doesn't implement the final screen, doesn't release the ticket and doesn't call anyone: the next step belongs to whoever invoked it.
