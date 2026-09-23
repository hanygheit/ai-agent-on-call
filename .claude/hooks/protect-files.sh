#!/usr/bin/env bash
# protect-files.sh — secrets are off-limits; the agent's own guardrails,
# CI and ops scripts need a human to approve any edit.
# PreToolUse · matcher "Read|Edit|Write|MultiEdit|NotebookEdit"
# shellcheck source=_lib.sh
. "$(dirname "$0")/_lib.sh"

[ -n "$FILE_PATH" ] || no_opinion
glob_match "$FILE_PATH" "${PROTECTED_ALLOW_GLOBS[@]}" && no_opinion

if glob_match "$FILE_PATH" "${PROTECTED_DENY_GLOBS[@]}"; then
  decide deny "Protected secret ($MATCHED). Agents never read or write secrets. Ask a human for the value you need, or use a placeholder."
fi

case "$TOOL" in
  Edit|Write|MultiEdit|NotebookEdit)
    if glob_match "$FILE_PATH" "${PROTECTED_ASK_GLOBS[@]}"; then
      decide ask "Guardrail / CI / ops file ($MATCHED). Changing it changes what agents may do. A human must approve."
    fi ;;
esac
no_opinion
