#!/usr/bin/env bash
# The command-mode window of merge-gate: while it is open, a risk listed in the
# command-mode-risk block of docs/agents/merge-gate.md lands without a human.
# It closes on its own at the end time. Only the human opens it.
#
# Usage, from the repo root:
#   command-mode.sh on <end>   open until <end>: "06:00" (the next 06:00) or an absolute date-time; at most 24h ahead
#   command-mode.sh off        close now
#   command-mode.sh status     print open, expired or off
#   command-mode.sh path       print the window file
#
# The window lives outside the repo, one file per GitHub repo, in
# ${MERGE_GATE_STATE_DIR:-${XDG_STATE_HOME:-~/.local/state}/merge-gate}. Its
# end time is always written as an absolute date-time: a relative expression
# would never expire.
set -uo pipefail

fail() {
  echo "ERROR: $1" >&2
  exit 2
}

usage() {
  echo "Usage: command-mode.sh on <end> | off | status | path" >&2
  exit 2
}

source "$(dirname "${BASH_SOURCE[0]}")/command-mode-lib.sh" || {
  echo "ERROR: missing command-mode-lib.sh next to this script" >&2
  exit 2
}

case "${1:-}" in
  path)
    (($# == 1)) || usage
    command_mode_file || fail "could not read the GitHub repo"
    ;;
  on)
    (($# == 2)) || usage
    file=$(command_mode_file) || fail "could not read the GitHub repo"
    now=$(date +%s)
    if [[ "$2" =~ ^[0-9]{1,2}:[0-9]{2}$ ]]; then
      end=$(date -d "$2" +%s 2>/dev/null) || fail "invalid end time: $2"
      # A bare time already past today means the next one.
      if ((end <= now)); then
        end=$(date -d "tomorrow $2" +%s 2>/dev/null) || fail "invalid end time: $2"
      fi
    else
      command_mode_fixed_end "$2" || fail "invalid end time: $2 (use 06:00 or an absolute date-time)"
      end=$(date -d "$2" +%s 2>/dev/null) || fail "invalid end time: $2"
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
    file=$(command_mode_file) || fail "could not read the GitHub repo"
    rm -f "$file" || fail "could not remove $file"
    echo "COMMAND MODE OFF"
    ;;
  status)
    (($# == 1)) || usage
    file=$(command_mode_file) || fail "could not read the GitHub repo"
    command_mode_read "$file"
    case "$command_state" in
      open) echo "COMMAND MODE ON until $command_until" ;;
      off) echo "COMMAND MODE OFF" ;;
      *) echo "COMMAND MODE OFF: $command_state" ;;
    esac
    ;;
  *) usage ;;
esac
