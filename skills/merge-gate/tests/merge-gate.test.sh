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
mkdir -p "$tmp/bin" "$tmp/repo/docs/agents"
cat >"$tmp/bin/gh" <<FAKE
#!/usr/bin/env bash
args="\$*"
case "\$args" in
  "repo view"*) echo "acme/app" ;;
  *"closingIssuesReferences"*) echo "\${FAKE_CLOSES:-7}" ;;
  "pr view"*) printf 'OPEN\tfalse\tmain\tMERGEABLE\t$head_sha\t2026-11-20T10:00:00Z\n' ;;
  "api graphql"*) printf 'OPEN\t%s\t-\n' "\${FAKE_LABELS:-risk:high}" ;;
  *check-runs*) echo "\${FAKE_CHECK:-success}" ;;
  *compare*) echo 0 ;;
  *"/files"*) printf '%b\n' "\${FAKE_FILES:-modified\tsrc/app.go\t}" ;;
  *"/comments"*) printf '<!-- REVIEWER-VERDICT -->\037Verdict: approve\037Commit: $head_sha\037Round: 1/2\n' ;;
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
    printf '```checks\nCI\n```\n```sensitive-paths\n^deploy/\n```\n'
    printf '```auto-merge-risk\nrisk:low\nrisk:medium\n```\n'
    [[ "${1:-}" == with-command-mode ]] && printf '```command-mode-risk\nrisk:high\n```\n'
    printf '```marker\n<!-- REVIEWER-VERDICT -->\n```\n'
  } >"$tmp/repo/docs/agents/merge-gate.md"
}
git -C "$tmp/repo" init -q

export PATH="$tmp/bin:$PATH" MERGE_GATE_STATE_DIR="$tmp/state"
window="$tmp/state/acme__app.command-mode"

failures=0
run_gate() {
  (cd "$tmp/repo" && env "$@" "$gate" 42 2>&1)
}
expect() { # name, expected exit, expected text, then the env for the gate
  local name=$1 code=$2 text=$3 out status
  shift 3
  out=$(run_gate "$@")
  status=$?
  if [[ "$status" == "$code" && "$out" == *"$text"* ]]; then
    echo "ok   $name"
  else
    echo "FAIL $name: exit $status, expected $code with '$text'"
    sed 's/^/     /' <<<"$out"
    failures=$((failures + 1))
  fi
}
set_window() { mkdir -p "$tmp/state" && printf '%s\n' "$1" >"$window"; }
iso() { date -d "$1" -Iseconds; }

# Without the command-mode block, nothing changes.
write_config
rm -f "$window"
expect "risk:medium clears as before" 0 "CLEARED: PR 42" FAKE_LABELS=risk:medium
set_window "$(iso '+2 hours')"
expect "risk:high without the command-mode block calls the human, even with a window" 10 "risk needs human approval" FAKE_LABELS=risk:high

write_config with-command-mode
rm -f "$window"
expect "risk:high without a window calls the human" 10 "command mode: off" FAKE_LABELS=risk:high
set_window "$(iso '-1 minute')"
expect "risk:high with an expired window calls the human" 10 "command mode: expired at" FAKE_LABELS=risk:high
set_window "$(iso '+30 hours')"
expect "risk:high with a window over 24h calls the human" 10 "ends more than 24h ahead" FAKE_LABELS=risk:high
set_window "not a date"
expect "risk:high with an invalid window calls the human" 10 "invalid end time" FAKE_LABELS=risk:high

set_window "$(iso '+2 hours')"
expect "risk:high inside the window clears" 0 "CLEARED: PR 42" FAKE_LABELS=risk:high
expect "the output says command mode cleared it" 0 "COMMAND MODE: risk:high cleared only because the command-mode window is open until" FAKE_LABELS=risk:high
out=$(run_gate FAKE_LABELS=risk:medium)
if [[ "$out" == *"COMMAND MODE"* ]]; then
  echo "FAIL risk:medium does not mention command mode"; failures=$((failures + 1))
else
  echo "ok   risk:medium does not mention command mode"
fi

# Inside the window, every other check still holds for risk:high.
expect "inside the window: a sensitive path calls the human" 10 "sensitive path: deploy/x.yml" FAKE_LABELS=risk:high 'FAKE_FILES=modified\tdeploy/x.yml\t'
expect "inside the window: a removed test calls the human" 10 "removes a test" FAKE_LABELS=risk:high 'FAKE_FILES=removed\tsrc/app_test.go\t'
expect "inside the window: a red check calls the human" 10 "check 'CI': failure" FAKE_LABELS=risk:high FAKE_CHECK=failure
expect "inside the window: two tickets call the human" 10 "exactly one ticket" FAKE_LABELS=risk:high FAKE_CLOSES=7,8
expect "inside the window: a running check waits for CI" 11 "WAITING FOR CI" FAKE_LABELS=risk:high FAKE_CHECK=in_progress

# command-mode.sh
check_mode() { # name, expected exit, expected text, args
  local name=$1 code=$2 text=$3 out status
  shift 3
  out=$(cd "$tmp/repo" && "$mode" "$@" 2>&1)
  status=$?
  if [[ "$status" == "$code" && "$out" == *"$text"* ]]; then
    echo "ok   $name"
  else
    echo "FAIL $name: exit $status, expected $code with '$text': $out"
    failures=$((failures + 1))
  fi
}
rm -f "$window"
check_mode "status with no window" 0 "COMMAND MODE OFF" status
check_mode "on refuses the past" 2 "in the past" on "$(iso '-1 hour')"
check_mode "on refuses more than 24h" 2 "more than 24h" on "$(iso '+25 hours')"
check_mode "on opens the window" 0 "COMMAND MODE ON until" on "$(iso '+3 hours')"
check_mode "status shows it open" 0 "COMMAND MODE ON until" status
expect "the window from command-mode.sh clears risk:high" 0 "COMMAND MODE: risk:high" FAKE_LABELS=risk:high
check_mode "a bare past time means the next one" 0 "COMMAND MODE ON until" on "$(date -d '-1 hour' +%H:%M)"
check_mode "off closes it" 0 "COMMAND MODE OFF" off
check_mode "status after off" 0 "COMMAND MODE OFF" status
expect "after off, risk:high calls the human" 10 "command mode: off" FAKE_LABELS=risk:high

((failures == 0)) && echo "all passed" || { echo "$failures failed"; exit 1; }
