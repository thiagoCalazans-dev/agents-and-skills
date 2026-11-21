#!/usr/bin/env bash
# Gate for merging without a human. When in doubt, call the human.
#
# Usage: merge-gate.sh <PR>
# Exit: 0 cleared, 10 call the human, 11 waiting for CI, 2 lookup error.
#
# It never merges. When cleared, it prints the merge command to run right after
# it, in the same command line, so the agent host sees the merge and applies
# its own rule for it: merge-gate.sh <PR> && gh pr merge ...
#
# The rules come from docs/agents/merge-gate.md (written by setup-skills),
# from the code blocks with these names: checks, sensitive-paths,
# auto-merge-risk, marker and, optionally, merge-method and command-mode-risk.
# While the command-mode window, turned on by the human with command-mode.sh,
# is open (and the command-mode-risk block exists), a risk in command-mode-risk
# lands without a human and sensitive paths no longer block; every other check holds.
# The main branch comes from the main-branch block of docs/agents/commands.md.
set -uo pipefail

fail() {
  echo "ERROR: $1" >&2
  exit 2
}

pr="${1:-}"
if [[ ! "$pr" =~ ^[0-9]+$ ]] || (($# != 1)); then
  echo "Usage: merge-gate.sh <PR>" >&2
  exit 2
fi

root=$(git rev-parse --show-toplevel) || fail "not inside a git repository"
config="$root/docs/agents/merge-gate.md"
[[ -f "$config" ]] || fail "no $config: run setup-skills"
commands="$root/docs/agents/commands.md"
[[ -f "$commands" ]] || fail "no $commands: run setup-skills"

# Lines of a named code block in the config file, without blank lines.
block() {
  awk -v name="$1" '
    $0 ~ "^```" name "[[:space:]]*$" { inside = 1; next }
    inside && /^```/ { exit }
    inside && NF { print }
  ' "${2:-$config}"
}

mapfile -t required_checks < <(block checks)
mapfile -t sensitive_paths < <(block sensitive-paths)
mapfile -t auto_risk < <(block auto-merge-risk)
mapfile -t command_risk < <(block command-mode-risk)
marker=$(block marker | head -1)
method=$(block merge-method | head -1)
method="${method:-merge}"
main_branch=$(block main-branch "$commands" | head -1)

((${#required_checks[@]} > 0)) || fail "empty 'checks' block in $config"
((${#auto_risk[@]} > 0)) || fail "empty 'auto-merge-risk' block in $config"
[[ -n "$marker" ]] || fail "empty 'marker' block in $config"
[[ -n "$main_branch" ]] || fail "empty 'main-branch' block in $commands"
[[ "$method" =~ ^(merge|squash|rebase)$ ]] || fail "invalid merge-method: $method"

reasons=()
refuse() { reasons+=("$1"); }

# The command-mode window: open while its end time is in the future, and never
# trusted for more than a day ahead. Sets command_state to open or the reason it is not.
command_state="off"
command_until=""
command_window() {
  local file now end
  file=$("$(dirname "${BASH_SOURCE[0]}")/command-mode.sh" path) || { command_state="unreadable"; return; }
  [[ -f "$file" ]] || return
  command_until=$(head -1 "$file")
  now=$(date +%s)
  if ! end=$(date -d "$command_until" +%s 2>/dev/null); then
    command_state="invalid end time ($command_until)"
  elif ((end <= now)); then
    command_state="expired at $command_until"
  elif ((end - now > 86400)); then
    command_state="ends more than 24h ahead ($command_until)"
  else
    command_state="open"
  fi
}

# Read the window once, and only for repos that use command mode.
((${#command_risk[@]} > 0)) && command_window

# The PR.
fields=$(gh pr view "$pr" --json state,isDraft,baseRefName,mergeable,headRefOid,createdAt \
  --jq '[.state, .isDraft, .baseRefName, .mergeable, .headRefOid, .createdAt] | @tsv') ||
  fail "could not read PR $pr"
IFS=$'\t' read -r state draft base mergeable head created <<<"$fields"
[[ -n "${head:-}" ]] || fail "PR $pr has no commit"

[[ "$state" == "OPEN" ]] || refuse "PR is not open ($state)"
[[ "$draft" == "false" ]] || refuse "PR is a draft"
[[ "$base" == "$main_branch" ]] || refuse "base is not $main_branch ($base)"
[[ "$mergeable" == "MERGEABLE" ]] || refuse "GitHub does not confirm the merge ($mergeable)"

# The ticket: the PR closes exactly one, open, with a risk that allows merging without a human.
closes=$(gh pr view "$pr" --json closingIssuesReferences \
  --jq '[.closingIssuesReferences[].number] | map(tostring) | join(",")') ||
  fail "could not read the issues the PR closes"
if [[ -z "$closes" || "$closes" == *,* ]]; then
  refuse "the PR must close exactly one ticket; it closes: ${closes:-none}"
else
  ticket="$closes"
  issue=$(gh api graphql -F owner='{owner}' -F name='{repo}' -F number="$ticket" \
    -f query='query($owner: String!, $name: String!, $number: Int!) {
      repository(owner: $owner, name: $name) {
        issue(number: $number) { state lastEditedAt labels(first: 50) { nodes { name } } }
      }
    }' --jq '.data.repository.issue | [.state, ([.labels.nodes[].name] | join(",")), (.lastEditedAt // "-")] | @tsv') ||
    fail "could not read ticket #$ticket"
  IFS=$'\t' read -r ticket_state ticket_labels ticket_edited <<<"$issue"

  [[ "$ticket_state" == "OPEN" ]] || refuse "ticket #$ticket is not open ($ticket_state)"
  allowed=0
  for label in "${auto_risk[@]}"; do
    [[ ",$ticket_labels," == *",$label,"* ]] && allowed=1
  done
  command_label=""
  if ((!allowed)); then
    for label in "${command_risk[@]}"; do
      [[ ",$ticket_labels," == *",$label,"* ]] && command_label="$label"
    done
  fi
  if [[ -n "$command_label" ]]; then
    if [[ "$command_state" == "open" ]]; then
      allowed=1
    else
      refuse "ticket #$ticket risk $command_label needs human approval; command mode: $command_state"
    fi
  else
    ((allowed)) || refuse "ticket #$ticket risk needs human approval (labels: ${ticket_labels:-none})"
  fi
  # Dates in UTC and the same format: string comparison follows time order.
  if [[ "$ticket_edited" != "-" && "$ticket_edited" > "$created" ]]; then
    refuse "ticket #$ticket edited after the PR was opened"
  fi
fi

# The required checks, on the latest commit.
pending=()
for check in "${required_checks[@]}"; do
  result=$(gh api "repos/{owner}/{repo}/commits/$head/check-runs?per_page=100" \
    --jq ".check_runs | map(select(.name == \"$check\")) | sort_by(.started_at) | last | if . == null then \"missing\" else (.conclusion // .status) end") ||
    fail "could not read the checks"
  case "$result" in
    success) ;;
    queued | in_progress | waiting | pending | requested) pending+=("$check") ;;
    *) refuse "check '$check': $result" ;;
  esac
done

behind=$(gh api "repos/{owner}/{repo}/compare/$main_branch...$head" --jq '.behind_by') ||
  fail "could not compare with $main_branch"
[[ "$behind" == "0" ]] || refuse "branch is $behind commit(s) behind $main_branch; CI did not test the merge result"

# The files: no sensitive path (unless the command-mode window is open), no removed test.
released=()
files=$(gh api --paginate "repos/{owner}/{repo}/pulls/$pr/files" \
  --jq '.[] | [.status, .filename, (.previous_filename // "")] | @tsv') ||
  fail "could not read the PR files"
[[ -n "$files" ]] || refuse "PR has no files"
while IFS=$'\t' read -r file_status file previous; do
  [[ -n "${file:-}" ]] || continue
  for path in "$file" "$previous"; do
    [[ -n "$path" ]] || continue
    for pattern in "${sensitive_paths[@]}"; do
      [[ "$path" =~ $pattern ]] || continue
      if [[ "$command_state" == "open" ]]; then
        released+=("$path")
      else
        refuse "sensitive path: $path${command_risk:+; command mode: $command_state}"
      fi
      break
    done
  done
  if [[ "$file_status" == "removed" && "$file" =~ (_test\.|\.test\.|\.spec\.|/tests?/) ]]; then
    refuse "removes a test: $file"
  fi
done <<<"$files"

# The Reviewer verdict: the latest comment with the marker, approving the latest commit.
marker_json=$(printf '%s' "$marker" | sed 's/\\/\\\\/g; s/"/\\"/g')
opinion=$(gh api --paginate "repos/{owner}/{repo}/issues/$pr/comments" \
  --jq ".[] | select(.body | contains(\"$marker_json\")) | .body | gsub(\"\\r\"; \"\") | gsub(\"\\n\"; \"\\u001f\")" |
  tail -1 | tr '\037' '\n') || fail "could not read the PR comments"
field() { sed -nE "s/^$1:[[:space:]]*(.*[^[:space:]])[[:space:]]*$/\1/p" <<<"$opinion" | head -1; }
if [[ -z "$opinion" ]]; then
  refuse "no Reviewer verdict ($marker)"
else
  [[ "$(field Commit)" == "$head" ]] || refuse "verdict is for another commit: $(field Commit)"
  [[ "$(field Verdict)" == "approve" ]] || refuse "verdict: $(field Verdict)"
fi

if ((${#reasons[@]} > 0)); then
  echo "CALL THE HUMAN: PR $pr at $head"
  printf -- '- %s\n' "${reasons[@]}"
  exit 10
fi

if ((${#pending[@]} > 0)); then
  echo "WAITING FOR CI: PR $pr at $head"
  printf -- '- %s\n' "${pending[@]}"
  exit 11
fi

if [[ -n "$command_label" ]]; then
  echo "COMMAND MODE: $command_label cleared only because the command-mode window is open until $command_until"
fi
if ((${#released[@]} > 0)); then
  mapfile -t released < <(printf '%s\n' "${released[@]}" | sort -u)
  echo "COMMAND MODE: sensitive paths cleared only because the command-mode window is open until $command_until: $(printf '%s, ' "${released[@]}" | sed 's/, $//')"
fi
echo "CLEARED: PR $pr at $head"
echo "MERGE WITH: gh pr merge $pr --$method --match-head-commit $head"
