#!/bin/sh
# tests/run.sh - exercises larz-meter end to end against a throwaway wallet.
# Assumes `larz-meter` is on PATH (installed via the built .deb) and
# LARZSCRIPT_PATH=/usr/lib/larzos is set in the environment.
# Deliberately no `set -e`: several of the commands below are expected to
# fail (that's what's under test), and we need their exit codes, not an
# early abort.

FAIL=0
ok()  { echo "ok   - $1"; }
bad() { echo "FAIL - $1"; FAIL=1; }

# substring match without spawning a second shell (avoids $-in-quotes
# reinterpretation issues when the needle itself contains a '$')
contains() {
  case "$1" in
    *"$2"*) return 0 ;;
    *) return 1 ;;
  esac
}

WDIR="$(mktemp -d)"
export LARZOS_WALLET_CONF="$WDIR/wallet.toml"
export LARZOS_BUDGET_CONF="$WDIR/budget.toml"
export LARZOS_WALLET_DIR="$WDIR"

OUT="$(larz-meter --category t --price 0.01 -- echo hi)"; RC=$?
[ "$RC" -eq 0 ] && ok "successful run exits 0" || bad "successful run exits 0 (got $RC)"
contains "$OUT" 'charged $0.01' && ok "successful run charges the wallet" || bad "successful run charges the wallet"

OUT="$(larz-meter --category t --price 0.01 -- false)"; RC=$?
[ "$RC" -eq 1 ] && ok "failing command exits with the command's code" || bad "failing command exits with the command's code (got $RC)"
contains "$OUT" 'not charged' && ok "failing command is not charged" || bad "failing command is not charged"

# A marker *file*, not marker text in stdout: dry-run's own status message
# echoes the command line verbatim ("would ... run `touch marker`..."), so
# grepping stdout for the marker would false-positive on that description.
# Only an actual execution creates the file.
MARKER="$WDIR/ran"

printf '[budget]\nt = 0.01\n' > "$LARZOS_BUDGET_CONF"
OUT="$(larz-meter --category t --price 0.01 -- touch "$MARKER")"; RC=$?
[ "$RC" -eq 2 ] && ok "over-budget run is blocked (exit 2)" || bad "over-budget run is blocked (got $RC)"
[ -e "$MARKER" ] && bad "over-budget run executed the command anyway" || ok "over-budget run did not execute the command"

# separate, uncapped category - "t" is already at its cap from the test above
OUT="$(larz-meter --category dry --price 0.01 --dry-run -- touch "$MARKER")"; RC=$?
[ "$RC" -eq 0 ] && ok "dry-run exits 0" || bad "dry-run exits 0 (got $RC)"
[ -e "$MARKER" ] && bad "dry-run executed the command" || ok "dry-run does not run the command"

rm -rf "$WDIR"
exit $FAIL
