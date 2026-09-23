#!/usr/bin/env bash
# prod-guard.sh — Rules 14 + 15: prompts ask, hooks decide.
# PreToolUse · matcher "Bash"
#   DENY  → irreversible / high blast radius. Blocked even if a human asks in chat.
#   ASK   → changes shared state. A human approves in the permission prompt.
#   quiet → normal permission flow (settings.json allow/ask/deny still apply).
# With --read-only (used by the oncall-triage agent): anything not on the
# READ_ONLY_ALLOW list is denied.
# shellcheck source=_lib.sh
. "$(dirname "$0")/_lib.sh"

[ "$TOOL" = "Bash" ] || no_opinion
[ -n "$CMD" ] || no_opinion

if matches_any "$CMD" "${DENY_PATTERNS[@]}"; then
  decide deny "Irreversible, high blast radius (matched: $MATCHED). Never run this. Propose a reversible alternative and let a human decide."
fi

# Commands that touch secrets are treated like protected files.
if grep -Eiq -- '(^|[[:space:]/])(\.env([.][a-z0-9_-]+)?|secrets/|[a-z0-9_-]*\.pem|[a-z0-9_-]*\.tfstate|id_rsa)([[:space:]]|$)' <<<"$CMD" \
   && ! grep -Eiq -- '\.env\.example' <<<"$CMD"; then
  decide deny "Touches secrets (.env / secrets/ / keys / tfstate). Agents never read or move secrets."
fi

if [ "${1:-}" = "--read-only" ]; then
  # Read-only mode judges each part of a pipeline / command list separately.
  while IFS= read -r part; do
    part="$(sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' <<<"$part")"
    [ -n "$part" ] || continue
    matches_any "$part" "${READ_ONLY_ALLOW[@]}" \
      || decide deny "Read-only agent: '$part' is not on the read-only allowlist. Gather evidence and propose; a human applies changes."
  done < <(sed -E 's/(\&\&|\|\||;|\|)/\n/g' <<<"$CMD")
  no_opinion
fi

if matches_any "$CMD" "${ASK_PATTERNS[@]}"; then
  decide ask "This changes shared state (matched: $MATCHED). A human must approve. Cite your evidence and rollback plan."
fi
no_opinion
