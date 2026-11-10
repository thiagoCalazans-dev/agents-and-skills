# Issue tracker: GitHub

Issues, specs and PRs for this repo live on GitHub. Use the `gh` CLI for all operations.

## Issues

- **Create**: `gh issue create --title "..." --body "..."`. Use a heredoc for multi-line bodies.
- **Read**: `gh issue view <number> --json number,title,body,labels,comments`.
- **List**: `gh issue list --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'` with appropriate `--label` and `--state` filters.
- **Sub-issue of a spec**: `gh issue create --parent <spec> ...`, or `gh issue edit <spec> --add-sub-issue <child>` afterwards (`gh` 2.94+). Older `gh`: `gh api --method POST repos/<owner>/<repo>/issues/<spec>/sub_issues -F sub_issue_id=<child-db-id>` (database id, as in **Blocking**). Without sub-issues, put `Part of #<spec>` at the top of the child body.
- **Blocking**: GitHub's **native issue dependencies**, visible in the UI. Add an edge with `gh issue create --blocked-by <n>,<n> ...` or `gh issue edit <child> --add-blocked-by <blocker>` (`gh` 2.94+). Older `gh`: `gh api --method POST repos/<owner>/<repo>/issues/<child>/dependencies/blocked_by -F issue_id=<blocker-db-id>`, where the database id comes from `gh api repos/<owner>/<repo>/issues/<n> --jq .id` (_not_ the `#number` or `node_id`). Where dependencies aren't available, fall back to a `Blocked by: #<n>, #<n>` line at the top of the body. A ticket is unblocked when every blocker is closed.
- **Count open blockers**: `gh api repos/<owner>/<repo>/issues/<n> --jq .issue_dependencies_summary.blocked_by` (0 means startable).
- **Comment**: `gh issue comment <number> --body "..."`.
- **Labels**: `gh issue edit <number> --add-label "..."` / `--remove-label "..."`.
- **Close**: post the reason with `gh issue comment`, then `gh issue close <number>`. Issues with the `spec` role are never closed by agents.

## Pull requests

- **Open**: `gh pr create --base <main branch> --title "..." --body "..."`, with `Closes #<ticket>` on the first line of the body, and only that one.
- **Read**: `gh pr view <number> --json number,title,body,state,isDraft,headRefOid,mergeable`, `gh pr diff <number>` and `gh pr checks <number>`.
- **Comment**: `gh pr comment <number> --body "..."`.
- **Merge**: only through `merge-gate`. No agent runs `gh pr merge` directly.

Infer the repo from `git remote -v`; `gh` does this automatically when run inside a clone.

File issues only into the user's own repo, never into the repo these skills come from. In a fork, `gh` can default to the upstream parent, so before the first `gh issue create` of a session, check the target with `gh repo view --json nameWithOwner` and confirm it with the user if it is not theirs.

## Pull requests as a triage surface

**PRs as a request surface: no.** _(Set to `yes` if this repo treats external PRs as feature requests; `/triage` reads this flag.)_

When set to `yes`, PRs run through the same labels and states as issues:

- **Read**: `gh pr view <number>`, then `gh pr view <number> --comments` and `gh pr diff <number>`.
- **List external PRs**: `gh api --paginate 'repos/{owner}/{repo}/pulls?state=open' --jq '.[] | select(.author_association | IN("OWNER","MEMBER","COLLABORATOR") | not) | {number, title, author: .user.login, author_association, labels: [.labels[].name]}'`.
- **Comment / label / close**: `gh pr comment`, `gh pr edit --add-label`/`--remove-label`, `gh pr close`.

GitHub shares one number space across issues and PRs, so a bare `#42` may be either: resolve with `gh pr view 42` and fall back to `gh issue view 42`.

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

Read it as in **Read** under Issues.
