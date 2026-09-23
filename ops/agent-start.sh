#!/usr/bin/env bash
# Release the kill switch. Only after the cause is understood.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
if [ -f "$root/.claude/AGENT_STOP" ]; then
  echo "Was: $(cat "$root/.claude/AGENT_STOP")"
  rm -f "$root/.claude/AGENT_STOP"
  echo "✅ Kill switch OFF."
else
  echo "Kill switch was not active."
fi
