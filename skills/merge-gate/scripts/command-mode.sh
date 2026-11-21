#!/usr/bin/env bash
# The command-mode window of merge-gate: while it is open, a risk listed in the
# command-mode-risk block of docs/agents/merge-gate.md lands without a human.
# It closes on its own at the end time. Only the human opens it.
#
# Usage, from the repo root:
#   command-mode.sh on <end>   open until <end>: "06:00" (the next 06:00) or an ISO date-time; at most 24h ahead
#   command-mode.sh off        close now
#   command-mode.sh status     print open, expired or off
#   command-mode.sh path       print the window file
#
# The window lives outside the repo, one file per GitHub repo, in
# ${MERGE_GATE_STATE_DIR:-${XDG_STATE_HOME:-~/.local/state}/merge-gate}.
set -uo pipefail

fail() {
  echo "ERROR: $1" >&2
  exit 2
}

usage() {
  echo "Usage: command-mode.sh on <end> | off | status | path" >&2
  exit 2
}

window_file() {
  local repo dir
  repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner) || fail "could not read the GitHub repo"
  [[ "$repo" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]] || fail "unexpected repo name: $repo"
  dir="${MERGE_GATE_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/merge-gate}"
  echo "$dir/${repo/\//__}.command-mode"
}

case "${1:-}" in
  path)
    (($# == 1)) || usage
    window_file
    ;;
  on)
    (($# == 2)) || usage
    file=$(window_file) || exit 2
    now=$(date +%s)
    end=$(date -d "$2" +%s 2>/dev/null) || fail "invalid end time: $2"
    # A bare time already past today means the next one.
    if [[ "$2" =~ ^[0-9]{1,2}:[0-9]{2}$ ]] && ((end <= now)); then
      end=$(date -d "tomorrow $2" +%s) || fail "invalid end time: $2"
    fi
    ((end > now)) || fail "end time is in the past: $2"
    ((end - now <= 86400)) || fail "end time is more than 24h ahead: $2"
    mkdir -p "$(dirname "$file")" || fail "could not create $(dirname "$file")"
    until=$(date -d "@$end" -Iseconds)
    printf '%s\nopened: %s\n' "$until" "$(date -Iseconds)" >"$file" || fail "could not write $file"
    echo "COMMAND MODE ON until $until"
    ;;
  off)
    (($# == 1)) || usage
    file=$(window_file) || exit 2
    rm -f "$file" || fail "could not remove $file"
    echo "COMMAND MODE OFF"
    ;;
  status)
    (($# == 1)) || usage
    file=$(window_file) || exit 2
    if [[ ! -f "$file" ]]; then
      echo "COMMAND MODE OFF"
      exit 0
    fi
    until=$(head -1 "$file")
    end=$(date -d "$until" +%s 2>/dev/null) || { echo "COMMAND MODE OFF: invalid end time ($until)"; exit 0; }
    now=$(date +%s)
    if ((end > now + 86400)); then
      echo "COMMAND MODE OFF: ends more than 24h ahead ($until)"
    elif ((end > now)); then
      echo "COMMAND MODE ON until $until"
    else
      echo "COMMAND MODE OFF: expired at $until"
    fi
    ;;
  *) usage ;;
esac
