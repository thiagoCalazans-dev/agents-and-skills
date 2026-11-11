---
name: verify-app
description: Proves with evidence that a change works in the running app, along the user's path, beyond the automated tests. Starts the app the way the project says, walks the flows the diff touches, keeps screenshots and the final state, writes a summary and leaves the machine as it was. Use when asked to verify, check or prove a change or a PR in the running app.
---

# Verify the running app

Tests say the rules still hold. Verification shows the change working as the user sees it, with evidence someone else can check. It does not replace the tests.

Read the "Evidence" section of `docs/agents/commands.md`: the level, the commands and the evidence folder. Without `docs/agents/`, tell the user to run `setup-skills` and stop. With level `none`, end in `no evidence configured`.

The two levels:
- **Browser:** you start the app with the "Start" command, walk the screen in the available browser and take the screenshots. There are no scripts.
- **Journeys:** the project has scripts that walk each flow. You choose which to run and run them with the "Run" command.

## Rules

- **Along the user's path.** Sign in through the login screen, click what they click and check what they see. Setup data may come through an API or the database; what is being proved may not.
- **Never weaken a verification to make it pass.** If the data doesn't meet a precondition, it fails, and the reason goes into the summary.
- **A failure you can't explain is the result.** Report it; don't rerun until it passes.
- **Test data only.** Use the test data in `commands.md`. Don't read credential files or print passwords. What depends on a real external service stays as "manual verification", never as proved.
- **Don't touch what isn't yours.** Use only the instance you started. Don't stop or change someone else's dev environment, the ports listed under "Concurrency" or other projects on the machine.
- **Don't change product code.** If the verification needs a route or a product change, end in `blocked`.
- **Always clean up.** After any attempt, even a failed one, run phase 5.

## 1. Choose what to verify

Read the diff (`git diff <main branch>...HEAD`) and, if there is one, the ticket: the acceptance criteria and the `Design` section.

- **Journeys:** find in the flow map from `commands.md` the flows the diff touches. With no clear link, or a broad change, run them all.
- **Browser:** list the screen paths that the acceptance criteria describe and the diff touches.

If the diff touches nothing the user sees, and no flow in the map, end in `nothing to verify` with the reason.

**A change no journey covers:**
- If the ticket asks for a new journey (a `New journey:` line in the `Read` section), create it where and in the format the flow map describes, along with its line in the map. It goes into the PR.
- If it doesn't, write a provisional journey inside the run's evidence folder. It counts only for this PR and is not committed.

## 2. Start

Run the "Start" command. Then, if there is one, run "Check". If it warns that the instance was built from another commit, start over: the evidence wouldn't prove the current change. Uncommitted files in the worktree: say so in the summary.

If the app doesn't start, run phase 5 and end in `environment did not start` with the reason and the log path.

## 3. Walk

Each flow is a sequence of steps. Each step has a title, the user's actions, what is expected on screen and a numbered screenshot (`NN-<step>.png`) in the flow's folder inside the evidence folder. Every flow ends in a step that checks the final state, in the database or through the API, not just the screen.

- **Journeys:** run the "Run" command with the chosen flows, one at a time.
- **Browser:** walk each path in the browser, at the screen sizes in `docs/agents/design.md`. Use roles and visible names, never coordinates. Save the screenshots and write `summary.md` in the flow's folder, with the steps, what you saw at each one and the final state.

A flow also fails, with every step right, on a 5xx response or a JavaScript error on screen.

**If the ticket has a `Design` section:** compare the screenshots with the approved ones on the ticket and note each difference in the flow's summary.

## 4. Summarize

Write `SUMMARY.md` at the root of the evidence folder, in this format:

```markdown
# Verification <run id>

Commit: <sha>. Worktree: <clean | with uncommitted files>. Level: <browser | journeys>.

## Flows

| Flow | Result | Screenshots |
|---|---|---|
| <flow> | proved / failed: <step> / not proved: <reason> | <folder> |

## Comparison with the design

<differences per flow, or "no Design section on the ticket">

## Not proved

- <what stayed as manual verification, uncovered or dependent on a real service>

## Errors in the log

<error lines from the services, each explained, or "none">
```

Don't round up: a flow proves only what is in its steps. An unexplained error line in the log means the verification did not pass, even with every flow right.

## 5. Clean up

Run the "Clean up" command. It stops only what this run started and checks that no process, container or port is left. At the browser level with no command, stop the processes you started in phase 2 by process id, never by name. If anything is left, say so in the summary. Keep the evidence folder.

## 6. Publish to the PR (when asked)

Publish only screenshots this skill produced, with test data. Look at each one first. Any other screenshot, from an environment with real data say, needs the user's authorization.

```bash
~/.claude/skills/verify-app/scripts/publish-evidence.sh <PR> <evidence folder>
```

If only Codex has the skill, the script is at `~/.codex/skills/verify-app/scripts/publish-evidence.sh`. Always call it by the full path: `scripts/publish-evidence.sh` alone points to the repo.

The script stores the images and summaries in a loose commit pointed at by `refs/verify-app/<run>`, outside any branch, and comments on the PR with the images. It does not publish traces, failure videos or logs, which may hold requests and cookies. **If the repo is public, the images open for anyone.** The command to delete the ref is at the end of the comment; run it after the merge.

## Output

The last line of the reply is one of:

| Result | When |
|---|---|
| `verified <folder>` | every chosen flow was proved |
| `failed <folder>: <flow>` | some flow failed |
| `nothing to verify: <reason>` | the diff touches nothing the user sees |
| `environment did not start: <reason>` | phase 2 failed |
| `blocked: <reason>` | the verification needs a product change or something out of reach |
| `no evidence configured` | level `none` |
