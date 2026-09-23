#!/usr/bin/env bash
# Pull the kill switch: every agent tool call in this checkout is denied.
# Usage: ops/agent-stop.sh "reason"      Any engineer, any time.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
reason="${1:-stopped by $(whoami)}"
printf '%s — %s @ %s\n' "$reason" "$(whoami)" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >"$root/.claude/AGENT_STOP"
echo "🛑 Kill switch ON. All agent actions are denied. ($reason)"
echo "   Also revoke agent credentials if agents run outside this checkout."
echo "   Resume with: ops/agent-start.sh"
