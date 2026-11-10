# Issue tracker: Local Markdown

Issues and specs for this repo live as markdown files in `.scratch/`. There are no PRs: the pipeline flow (merge gate, verdict on the PR) needs GitHub or GitLab, so here a human does review and merge.

## Conventions

- One feature per directory: `.scratch/<feature-slug>/`.
- The spec is `.scratch/<feature-slug>/spec.md`.
- Each ticket is one file at `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01`, never a single combined tickets file.
- State is a `Status:` line at the top of each file, using the strings in `labels.md`. Risk is a `Risk:` line.
- Blocking is a `Blocked by: NN, NN` line. A ticket is unblocked when every file it lists has `Status: closed`, the state of a finished ticket.
- Comments and history append to the bottom of the file under a `## Comments` heading.

## When a skill says "publish to the issue tracker"

Create a new file under `.scratch/<feature-slug>/`, creating the directory if needed.

## When a skill says "fetch the relevant ticket"

Read the file at the referenced path. The user will normally pass the path or the issue number directly.
