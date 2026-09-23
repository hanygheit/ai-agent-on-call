#!/usr/bin/env bash
# Change freeze: agents may read and investigate, not change anything.
# Usage: ops/freeze.sh on "release 2026.10"  |  ops/freeze.sh off  |  ops/freeze.sh status
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
f="$root/.claude/FREEZE"
case "${1:-status}" in
  on)  printf '%s — %s @ %s\n' "${2:-change freeze}" "$(whoami)" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >"$f"; echo "🧊 Freeze ON: $(cat "$f")" ;;
  off) rm -f "$f"; echo "Freeze OFF." ;;
  status) if [ -f "$f" ]; then echo "🧊 Freeze ON: $(cat "$f")"; else echo "No freeze."; fi ;;
  *) echo "usage: $0 on [reason] | off | status" >&2; exit 1 ;;
esac
