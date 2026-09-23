#!/usr/bin/env bash
# kill-switch.sh — Rule 16: build the stop button first.
# PreToolUse · matcher "*"
# If .claude/AGENT_STOP exists, EVERY tool call is denied. Any engineer can
# pull it: `ops/agent-stop.sh "reason"`. Remove it with `ops/agent-start.sh`.
# shellcheck source=_lib.sh
. "$(dirname "$0")/_lib.sh"

if [ -f "$CLAUDE_DIR/AGENT_STOP" ]; then
  reason="$(head -n 1 "$CLAUDE_DIR/AGENT_STOP" 2>/dev/null)"
  decide deny "KILL SWITCH ACTIVE${reason:+ ($reason)}. All agent actions are stopped. Do not retry or work around this; tell the human and wait."
fi
no_opinion
