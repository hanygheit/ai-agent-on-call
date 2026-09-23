#!/usr/bin/env bash
# audit-log.sh — Rule 18: audit the why. One JSON line per action.
# PostToolUse · matcher "Bash|Edit|Write|MultiEdit|NotebookEdit"
# (Blocked attempts are logged by the PreToolUse hooks themselves.)
# Ship .claude/logs/agent-actions.jsonl to the same sink as human actions.
# shellcheck source=_lib.sh
. "$(dirname "$0")/_lib.sh"
audit "executed" "tool call completed"
exit 0
