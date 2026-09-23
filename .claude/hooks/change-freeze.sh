#!/usr/bin/env bash
# change-freeze.sh — "There is no way to enforce a code freeze in vibe coding
# apps." (Jason Lemkin, Jul 2025). Now there is.
# PreToolUse · matcher "Bash|Edit|Write|MultiEdit|NotebookEdit"
# While .claude/FREEZE exists: no file edits and no mutating commands.
# Reading, searching and investigating stay allowed.
# shellcheck source=_lib.sh
. "$(dirname "$0")/_lib.sh"

[ -f "$CLAUDE_DIR/FREEZE" ] || no_opinion
why="$(head -n 1 "$CLAUDE_DIR/FREEZE" 2>/dev/null)"
msg="CHANGE FREEZE${why:+ ($why)}: read and investigate only. Propose the change in chat; do not apply it."

case "$TOOL" in
  Edit|Write|MultiEdit|NotebookEdit) decide deny "$msg" ;;
  Bash)
    if matches_any "$CMD" "${DENY_PATTERNS[@]}" "${ASK_PATTERNS[@]}" "${FREEZE_EXTRA_PATTERNS[@]}"; then
      decide deny "$msg"
    fi ;;
esac
no_opinion
