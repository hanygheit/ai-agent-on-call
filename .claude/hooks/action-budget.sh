#!/usr/bin/env bash
# action-budget.sh — Rule 16: rate-limit hard. Knight Capital lost $440M in
# 45 minutes to fast automation without a brake.
# PreToolUse · matcher "Bash"
# More than ACTION_BUDGET_PER_MINUTE (or _PER_HOUR) Bash calls in one session
# → deny and ask for a human.
# shellcheck source=_lib.sh
. "$(dirname "$0")/_lib.sh"

[ "$TOOL" = "Bash" ] || no_opinion
now="$(date +%s)"
f="$STATE_DIR/budget-$(tr -c 'A-Za-z0-9_-' '_' <<<"$SESSION").log"

# keep only the last hour, then record this call
if [ -f "$f" ]; then
  awk -v t="$now" '$1 > t-3600' "$f" >"$f.tmp" 2>/dev/null && mv "$f.tmp" "$f"
fi
echo "$now" >>"$f"

per_min="$(awk -v t="$now" '$1 > t-60' "$f" | wc -l | tr -d ' ')"
per_hour="$(wc -l <"$f" | tr -d ' ')"

if [ "$per_min" -gt "${ACTION_BUDGET_PER_MINUTE:-10}" ]; then
  decide deny "Action budget exceeded: $per_min commands in the last minute (limit ${ACTION_BUDGET_PER_MINUTE:-10}). Stop, summarise what you are doing, and wait for a human."
fi
if [ "$per_hour" -gt "${ACTION_BUDGET_PER_HOUR:-120}" ]; then
  decide deny "Action budget exceeded: $per_hour commands this hour (limit ${ACTION_BUDGET_PER_HOUR:-120}). Pause and hand over to a human."
fi
no_opinion
