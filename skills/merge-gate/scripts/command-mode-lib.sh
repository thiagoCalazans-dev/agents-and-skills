#!/usr/bin/env bash
# Shared by merge-gate.sh and command-mode.sh: where the command-mode window
# lives and what it says right now. Sourced, never run.
#
# The window is a file outside the repo, one per GitHub repo, in
# ${MERGE_GATE_STATE_DIR:-${XDG_STATE_HOME:-~/.local/state}/merge-gate}. Its
# first line is the end time, always absolute.

# Print the window file of the current GitHub repo.
command_mode_file() {
  local repo dir
  repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner) || return 1
  [[ "$repo" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]] || return 1
  dir="${MERGE_GATE_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/merge-gate}"
  printf '%s/%s.command-mode\n' "$dir" "${repo/\//__}"
}

# True for an absolute end time: a date, with or without a time, seconds and
# offset. A relative expression ("+2 hours", "tomorrow", "now") never counts:
# it would move the end on every read, so the window would never close.
command_mode_fixed_end() {
  [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}([T\ ][0-9]{2}:[0-9]{2}(:[0-9]{2})?)?([+-][0-9]{2}:?[0-9]{2}|Z)?$ ]]
}

# Classify the window, always starting from closed. Sets command_state (off,
# open, invalid end time, expired at, ends more than 24h ahead) and
# command_until. Reading again later in the same run revalidates: a file gone
# or expired since the first read comes back closed instead of keeping the
# earlier answer.
command_mode_read() {
  local file=$1 until end now
  command_state="off"
  command_until=""
  [[ -f "$file" ]] || return 0
  until=$(head -1 "$file")
  command_until=$until
  command_mode_fixed_end "$until" || { command_state="invalid end time ($until)"; return 0; }
  end=$(date -d "$until" +%s 2>/dev/null) || { command_state="invalid end time ($until)"; return 0; }
  now=$(date +%s)
  if ((end <= now)); then
    command_state="expired at $until"
  elif ((end - now > 86400)); then
    command_state="ends more than 24h ahead ($until)"
  else
    command_state="open"
  fi
}
