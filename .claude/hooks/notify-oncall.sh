#!/usr/bin/env bash
# notify-oncall.sh — an agent waiting for approval should not wait in silence.
# Notification · matcher "permission_prompt"
# Posts to a Slack / Teams incoming webhook taken from $ONCALL_WEBHOOK_URL.
# Never put the URL in the repo: export it, or set it in settings.local.json "env".
# shellcheck source=_lib.sh
. "$(dirname "$0")/_lib.sh"

msg="$(json '.message')"; msg="${msg:-Claude Code is waiting for approval}"
text="🤖 Agent needs a human in $(basename "$ROOT") ($(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')): $msg"
audit "notified" "$msg"

if [ -n "${ONCALL_WEBHOOK_URL:-}" ] && command -v curl >/dev/null 2>&1; then
  # {"text": ...} works for Slack and for Teams incoming webhooks / workflows.
  jq -cn --arg t "$text" '{text:$t}' \
    | curl -fsS -m 5 -H 'Content-Type: application/json' -d @- "$ONCALL_WEBHOOK_URL" >/dev/null 2>&1 || true
fi
exit 0
