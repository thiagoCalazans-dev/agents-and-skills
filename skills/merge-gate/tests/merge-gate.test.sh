#!/usr/bin/env bash
# Tests for merge-gate.sh and command-mode.sh, with a fake gh. No network.
# Usage: skills/merge-gate/tests/merge-gate.test.sh
set -uo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
gate="$here/../scripts/merge-gate.sh"
mode="$here/../scripts/command-mode.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

head_sha=abc123
mkdir -p "$tmp/bin" "$tmp/hooks" "$tmp/repo/docs/agents"
cat >"$tmp/bin/gh" <<FAKE
#!/usr/bin/env bash
args="\$*"
case "\$args" in
  "repo view"*) echo "acme/app" ;;
  *"closingIssuesReferences"*) echo "\${FAKE_CLOSES:-7}" ;;
  "pr view"*) printf 'OPEN\tfalse\tmain\tMERGEABLE\t$head_sha\t2026-11-20T10:00:00Z\n' ;;
  "api graphql"*) printf 'OPEN\t%s\t-\n' "\${FAKE_LABELS:-risk:high}" ;;
  *check-runs*)
    # A real CI query takes a while: a hook can expire or close the window meanwhile.
    [[ -n "\${FAKE_CHECK_HOOK:-}" ]] && "\$FAKE_CHECK_HOOK"
    echo "\${FAKE_CHECK:-success}"
    ;;
  *compare*) echo 0 ;;
  *"/files"*) printf '%b\n' "\${FAKE_FILES:-modified\tsrc/app.go\t}" ;;
  *"/comments"*) printf '<!-- REVIEWER-VERDICT -->\037Verdict: approve\037Commit: %s\037Round: 1/2\n' "\${FAKE_COMMIT:-$head_sha}" ;;
  *) echo "fake gh: unexpected: \$args" >&2; exit 1 ;;
esac
FAKE
chmod +x "$tmp/bin/gh"

cat >"$tmp/repo/docs/agents/commands.md" <<'CFG'
```main-branch
main
```
CFG
write_config() {
  {
    printf '```checks\nCI\n```\n```sensitive-paths\n^deploy/\n^docs/agents/\n^\\.github/\n^auth/\n```\n'
    printf '```auto-merge-risk\nrisk:low\nrisk:medium\n```\n'
    [[ "${1:-}" == with-command-mode ]] && printf '```command-mode-risk\nrisk:high\n```\n'
    [[ "${2:-}" == with-locked ]] && printf '```command-mode-locked-paths\n^deploy/\n```\n'
    printf '```marker\n<!-- REVIEWER-VERDICT -->\n```\n'
  } >"$tmp/repo/docs/agents/merge-gate.md"
}
git -C "$tmp/repo" init -q

export PATH="$tmp/bin:$PATH" MERGE_GATE_STATE_DIR="$tmp/state"
window="$tmp/state/acme__app.command-mode"

failures=0
check() { # name, expected exit, expected text, then the command
  local name=$1 code=$2 text=$3 out status
  shift 3
  out=$("$@" 2>&1)
  status=$?
  if [[ "$status" == "$code" && "$out" == *"$text"* ]]; then
    echo "ok   $name"
  else
    echo "FAIL $name: exit $status, expected $code with '$text'"
    sed 's/^/     /' <<<"$out"
    failures=$((failures + 1))
  fi
}
gate_out() { (cd "$tmp/repo" && env "$@" "$gate" 42); }
mode_out() { (cd "$tmp/repo" && "$mode" "$@"); }
expect() { local name=$1 code=$2 text=$3; shift 3; check "$name" "$code" "$text" gate_out "$@"; }
check_mode() { local name=$1 code=$2 text=$3; shift 3; check "$name" "$code" "$text" mode_out "$@"; }
set_window() { mkdir -p "$tmp/state" && printf '%s\n' "$1" >"$window"; }
iso() { date -d "$1" -Iseconds; }

# Without the command-mode block, nothing changes.
write_config
rm -f "$window"
expect "risk:medium clears as before" 0 "CLEARED: PR 42" FAKE_LABELS=risk:medium
set_window "$(iso '+2 hours')"
expect "risk:high without the command-mode block calls the human, even with a window" 10 "risk needs human approval" FAKE_LABELS=risk:high
expect "a sensitive path without the command-mode block calls the human, even with a window" 10 "sensitive path: deploy/x.yml" FAKE_LABELS=risk:medium 'FAKE_FILES=modified\tdeploy/x.yml\t'

write_config with-command-mode
rm -f "$window"
expect "risk:high without a window calls the human" 10 "command mode: off" FAKE_LABELS=risk:high
set_window "$(iso '-1 minute')"
expect "risk:high with an expired window calls the human" 10 "command mode: expired at" FAKE_LABELS=risk:high
set_window "$(iso '+30 hours')"
expect "risk:high with a window over 24h calls the human" 10 "ends more than 24h ahead" FAKE_LABELS=risk:high
set_window "not a date"
expect "risk:high with an invalid window calls the human" 10 "invalid end time" FAKE_LABELS=risk:high
set_window "+2 hours"
expect "a relative end time in the window file calls the human" 10 "invalid end time (+2 hours)" FAKE_LABELS=risk:high
expect "a relative end time also blocks a sensitive path" 10 "sensitive path: deploy/x.yml; command mode: invalid end time (+2 hours)" FAKE_LABELS=risk:medium 'FAKE_FILES=modified\tdeploy/x.yml\t'

rm -f "$window"
expect "no window: a sensitive path calls the human" 10 "sensitive path: deploy/x.yml; command mode: off" FAKE_LABELS=risk:medium 'FAKE_FILES=modified\tdeploy/x.yml\t'
set_window "$(iso '-1 minute')"
expect "expired window: a sensitive path calls the human" 10 "sensitive path: deploy/x.yml; command mode: expired at" FAKE_LABELS=risk:medium 'FAKE_FILES=modified\tdeploy/x.yml\t'
set_window "$(iso '+30 hours')"
expect "window over 24h: a sensitive path calls the human" 10 "sensitive path: deploy/x.yml; command mode: ends more than 24h ahead" FAKE_LABELS=risk:medium 'FAKE_FILES=modified\tdeploy/x.yml\t'

set_window "$(iso '+2 hours')"
expect "risk:high inside the window clears" 0 "CLEARED: PR 42" FAKE_LABELS=risk:high
expect "the output says command mode cleared it" 0 "COMMAND MODE: risk:high cleared only because the command-mode window is open until" FAKE_LABELS=risk:high
out=$(gate_out FAKE_LABELS=risk:medium)
if [[ "$out" == *"COMMAND MODE"* ]]; then
  echo "FAIL risk:medium does not mention command mode"; failures=$((failures + 1))
else
  echo "ok   risk:medium does not mention command mode"
fi

# Inside the window, sensitive paths no longer block, and the output lists them.
SENS='FAKE_FILES=modified\tdeploy/x.yml\nmodified\tsrc/app.go\nrenamed\tdeploy/b.yml\tdeploy/a.yml'
expect "inside the window: a sensitive path clears" 0 "CLEARED: PR 42" FAKE_LABELS=risk:high "$SENS"
expect "inside the window: the output lists the cleared sensitive paths" 0 "COMMAND MODE: sensitive paths cleared only because the command-mode window is open until $(head -1 "$window"): deploy/a.yml, deploy/b.yml, deploy/x.yml" FAKE_LABELS=risk:high "$SENS"
expect "inside the window: risk:medium on a sensitive path clears" 0 "COMMAND MODE: sensitive paths cleared" FAKE_LABELS=risk:medium "$SENS"
out=$(gate_out FAKE_LABELS=risk:high)
if [[ "$out" == *"sensitive paths cleared"* ]]; then
  echo "FAIL no sensitive path, no sensitive-path line"; failures=$((failures + 1))
else
  echo "ok   no sensitive path, no sensitive-path line"
fi

# Inside the window, the gate's rules and the CI never clear (always locked).
expect "inside the window: docs/agents/ calls the human" 10 "gate rules path: docs/agents/merge-gate.md; never cleared by command mode" FAKE_LABELS=risk:high 'FAKE_FILES=modified\tdocs/agents/merge-gate.md\nmodified\tdeploy/x.yml\t'
expect "inside the window: .github/ calls the human" 10 "gate rules path: .github/workflows/ci.yml; never cleared by command mode" FAKE_LABELS=risk:medium 'FAKE_FILES=modified\t.github/workflows/ci.yml\t'
expect "inside the window: a rename out of docs/agents/ calls the human" 10 "gate rules path: docs/agents/old.md" FAKE_LABELS=risk:high 'FAKE_FILES=renamed\tsrc/new.md\tdocs/agents/old.md'
out=$(gate_out FAKE_LABELS=risk:high 'FAKE_FILES=modified\tdocs/agents/merge-gate.md\nmodified\tdeploy/x.yml\t')
if [[ "$out" == *"sensitive path: deploy/x.yml"* || "$out" == *"CLEARED"* ]]; then
  echo "FAIL inside the window: only the gate rules path blocks"; failures=$((failures + 1))
else
  echo "ok   inside the window: only the gate rules path blocks"
fi

# A command-mode-locked-paths block adds to the always-locked paths: it can
# never take docs/agents/ or .github/ out of the list.
write_config with-command-mode with-locked
expect "custom locked list: its own path calls the human" 10 "gate rules path: deploy/x.yml; never cleared by command mode" FAKE_LABELS=risk:high 'FAKE_FILES=modified\tdeploy/x.yml\t'
expect "custom locked list cannot remove .github/" 10 "gate rules path: .github/workflows/ci.yml; never cleared by command mode" FAKE_LABELS=risk:high 'FAKE_FILES=modified\t.github/workflows/ci.yml\t'
expect "custom locked list cannot remove docs/agents/" 10 "gate rules path: docs/agents/merge-gate.md; never cleared by command mode" FAKE_LABELS=risk:medium 'FAKE_FILES=modified\tdocs/agents/merge-gate.md\t'
expect "custom locked list: other sensitive paths still clear" 0 "COMMAND MODE: sensitive paths cleared" FAKE_LABELS=risk:high 'FAKE_FILES=modified\tauth/login.go\t'
write_config with-command-mode

# The window must still be open when the decision is made: a CI query can take
# long enough for it to expire or be turned off meanwhile.
cat >"$tmp/hooks/expire" <<HOOK
#!/usr/bin/env bash
# The window ends while the CI query runs.
printf '%s\n' "\$(date -d '-1 minute' -Iseconds)" >"$window"
HOOK
cat >"$tmp/hooks/turn-off" <<HOOK
#!/usr/bin/env bash
rm -f "$window"
HOOK
chmod +x "$tmp/hooks/expire" "$tmp/hooks/turn-off"
set_window "$(iso '+2 hours')"
expect "a window expiring while the gate runs calls the human" 10 "command mode closed while the gate ran: expired at" FAKE_LABELS=risk:high FAKE_CHECK_HOOK="$tmp/hooks/expire"
set_window "$(iso '+2 hours')"
expect "a window expiring while the gate runs also refuses a sensitive path" 10 "command mode closed while the gate ran: expired at" FAKE_LABELS=risk:medium 'FAKE_FILES=modified\tdeploy/x.yml\t' FAKE_CHECK_HOOK="$tmp/hooks/expire"
set_window "$(iso '+2 hours')"
expect "a window turned off while the gate runs calls the human" 10 "command mode closed while the gate ran: off" FAKE_LABELS=risk:high FAKE_CHECK_HOOK="$tmp/hooks/turn-off"

# Inside the window, every other check still holds.
set_window "$(iso '+2 hours')"
expect "inside the window: a sensitive path with a removed test calls the human" 10 "removes a test" FAKE_LABELS=risk:high 'FAKE_FILES=modified\tdeploy/x.yml\nremoved\tsrc/app_test.go\t'
expect "inside the window: a sensitive path with a red check calls the human" 10 "check 'CI': failure" FAKE_LABELS=risk:high FAKE_CHECK=failure "$SENS"
expect "inside the window: a sensitive path with no verdict for the commit calls the human" 10 "verdict is for another commit" FAKE_LABELS=risk:high FAKE_COMMIT=old999 "$SENS"
expect "inside the window: a removed test calls the human" 10 "removes a test" FAKE_LABELS=risk:high 'FAKE_FILES=removed\tsrc/app_test.go\t'
expect "inside the window: a red check calls the human" 10 "check 'CI': failure" FAKE_LABELS=risk:high FAKE_CHECK=failure
expect "inside the window: two tickets call the human" 10 "exactly one ticket" FAKE_LABELS=risk:high FAKE_CLOSES=7,8
expect "inside the window: a running check waits for CI" 11 "WAITING FOR CI" FAKE_LABELS=risk:high FAKE_CHECK=in_progress

# command-mode.sh
rm -f "$window"
check_mode "status with no window" 0 "COMMAND MODE OFF" status
check_mode "on refuses the past" 2 "in the past" on "$(iso '-1 hour')"
check_mode "on refuses more than 24h" 2 "more than 24h" on "$(iso '+25 hours')"
check_mode "on refuses a relative end" 2 "use 06:00 or an absolute date-time" on "+2 hours"
check_mode "on opens the window" 0 "COMMAND MODE ON until" on "$(iso '+3 hours')"
check_mode "status shows it open" 0 "COMMAND MODE ON until" status
set_window "+2 hours"
check_mode "status refuses a relative end in the file" 0 "COMMAND MODE OFF: invalid end time (+2 hours)" status
rm -f "$window"
check_mode "on opens the window" 0 "COMMAND MODE ON until" on "$(iso '+3 hours')"
expect "the window from command-mode.sh clears risk:high" 0 "COMMAND MODE: risk:high" FAKE_LABELS=risk:high
check_mode "a bare past time means the next one" 0 "COMMAND MODE ON until" on "$(date -d '-1 hour' +%H:%M)"
check_mode "off closes it" 0 "COMMAND MODE OFF" off
check_mode "status after off" 0 "COMMAND MODE OFF" status
expect "after off, risk:high calls the human" 10 "command mode: off" FAKE_LABELS=risk:high
expect "after off, docs/agents/ calls the human as a sensitive path" 10 "sensitive path: docs/agents/merge-gate.md; command mode: off" FAKE_LABELS=risk:medium 'FAKE_FILES=modified\tdocs/agents/merge-gate.md\t'
expect "after off, a sensitive path calls the human" 10 "sensitive path: deploy/x.yml; command mode: off" FAKE_LABELS=risk:medium 'FAKE_FILES=modified\tdeploy/x.yml\t'

((failures == 0)) && echo "all passed" || { echo "$failures failed"; exit 1; }
