# Commands

The commands of this repo that the skills run, from the repo root. This file is the source of truth for agents; the `Makefile`, `package.json` or equivalent is the source of truth for people. Keep the two in agreement.

| For | Command |
|---|---|
| Start the dev environment | `<command>` |
| Restart the environment on the current branch | `<command, if any>` |
| Tests | `<command>` |
| Lint and formatting | `<command>` |
| Generated-code check | `<command, if any>` |
| UI prototype | `<command that runs the prototype from a prototype/* branch>` |

## Main branch

The branch PRs merge into and other branches start from. The skills and the `merge-gate` script read this block; keep the block's name.

```main-branch
<main>
```

## Evidence

How `verify-app` proves a change works in the running app.

- **Level:** `<none | browser | journeys>`
  - `none`: tests only.
  - `browser`: the agent starts the app and walks the screen in the browser, with no scripts.
  - `journeys`: project scripts walk each flow.
- **Start:** `<command that starts an instance just for the verification>` (browser and journeys)
- **Check:** `<command that checks the instance, if any>`
- **Run:** `<command> <flow...>` (journeys only)
- **Clean up:** `<command that stops only what the verification started>`
- **Evidence folder:** `<folder ignored by git, one subfolder per run>`
- **Flow map:** `<file linking each flow to its journey and the parts of the app it covers>` (journeys only)
- **Test data:** `<how to sign in and set up data without real data; never the password in this file>`

## When running

- When filtering output (`| tail`, `| grep`), start with `set -o pipefail`, so a failing command isn't hidden by the filter.
- Check the lint and test results before committing, pushing or opening the PR. Don't chain them into one command.

## Concurrency

- **Fixed ports:** `<yes: list them | no>`
- **Parallel tasks:** `<one at a time | up to N>`. With fixed ports, one at a time.

## Manual testing (optional)

<!-- If the repo leaves the environment ready for a human to test the PR: the command, the URL, and where the test credentials live (never the password in this file). -->
