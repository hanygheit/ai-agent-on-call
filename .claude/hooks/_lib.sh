# shellcheck shell=bash
# shellcheck disable=SC2034  # MATCHED is read by the hooks that source this file
# Shared helpers for every guardrail hook. Sourced, never executed directly.
#
# Contract (Claude Code hooks): the hook receives the event as JSON on stdin.
#   - print nothing + exit 0          → no opinion; normal permission flow applies
#   - print hookSpecificOutput JSON   → allow | ask | deny (PreToolUse)
#   - exit 2 + message on stderr      → hard block (used when we must FAIL CLOSED)
# Docs: https://code.claude.com/docs/en/hooks

set -uo pipefail

HOOK_NAME="$(basename "${BASH_SOURCE[1]:-$0}" .sh)"
ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
CLAUDE_DIR="$ROOT/.claude"
STATE_DIR="$CLAUDE_DIR/state"

# Fail closed: a guardrail that cannot run must block, not silently pass.
# (Claude Code treats a crashing hook / exit 1 as NON-blocking.)
fail_closed() {
  echo "[$HOOK_NAME] guardrail unavailable: $1 — blocking to stay safe." >&2
  exit 2
}

command -v jq >/dev/null 2>&1 || fail_closed "jq is not installed (brew install jq / apt-get install jq)"
[ -f "$CLAUDE_DIR/guardrails.env" ] || fail_closed "missing $CLAUDE_DIR/guardrails.env"
# shellcheck source=../guardrails.env
. "$CLAUDE_DIR/guardrails.env" || fail_closed "cannot load guardrails.env"

INPUT="$(cat)"
# Unparseable input is abnormal: block rather than guess.
jq -e . >/dev/null 2>&1 <<<"$INPUT" || fail_closed "hook input is not valid JSON"
json() { jq -r "$1 // empty" <<<"$INPUT" 2>/dev/null; }

EVENT="$(json '.hook_event_name')"
TOOL="$(json '.tool_name')"
SESSION="$(json '.session_id')"; SESSION="${SESSION:-unknown}"
CMD="$(json '.tool_input.command')"
FILE_PATH="$(json '.tool_input.file_path // .tool_input.notebook_path // .tool_input.path')"

mkdir -p "$STATE_DIR" 2>/dev/null || true

# Rule 18: pin the policy version into every audit line.
guardrails_version() {
  cat "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/guardrails.env" 2>/dev/null \
    | { sha256sum 2>/dev/null || shasum -a 256; } | cut -c1-12
}

audit() { # $1 = decision, $2 = reason
  local log="$ROOT/${AUDIT_LOG_PATH:-.claude/logs/agent-actions.jsonl}"
  mkdir -p "$(dirname "$log")" 2>/dev/null || return 0
  jq -cn \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg session "$SESSION" --arg event "$EVENT" --arg tool "$TOOL" \
    --arg hook "$HOOK_NAME" --arg decision "$1" --arg reason "${2:-}" \
    --arg command "$CMD" --arg file "$FILE_PATH" \
    --arg branch "$(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo n/a)" \
    --arg policy "$(guardrails_version)" \
    --arg actor "agent:${USER:-unknown}" \
    '{ts:$ts, actor:$actor, session:$session, event:$event, tool:$tool, hook:$hook,
      decision:$decision, reason:$reason, command:$command, file:$file,
      branch:$branch, policy_version:$policy}' >>"$log" 2>/dev/null || true
}

decide() { # $1 = allow | ask | deny, $2 = reason (shown to Claude on deny)
  audit "$1" "$2"
  jq -n --arg d "$1" --arg r "[$HOOK_NAME] $2" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:$d, permissionDecisionReason:$r}}'
  exit 0
}

no_opinion() { exit 0; }
MATCHED=""

# matches_any "<text>" "${ARRAY[@]}" → 0 if any ERE matches (case-insensitive)
matches_any() {
  local text="$1"; shift
  local p
  for p in "$@"; do
    [ -n "$p" ] || continue
    if grep -Eiq -- "$p" <<<"$text"; then MATCHED="$p"; return 0; fi
  done
  return 1
}

# glob_match "<path>" "${GLOBS[@]}" → 0 if the path (relative to ROOT) matches
glob_match() {
  local path="$1"; shift
  path="${path#"$ROOT"/}"; path="${path#./}"
  local g
  for g in "$@"; do
    # shellcheck disable=SC2254
    case "$path" in $g) MATCHED="$g"; return 0 ;; esac
  done
  return 1
}
