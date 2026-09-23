#!/usr/bin/env bash
# test-hooks.sh — offline tests for every guardrail hook. Runs in CI (Rule 11:
# the guardrails are tested by something other than the agent).
# No Claude Code, no network, no kubectl needed: we feed each hook the same JSON
# Claude Code would send on stdin and assert the decision it returns.
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS="$REPO/.claude/hooks"
command -v jq >/dev/null || { echo "jq is required"; exit 1; }

# Each test runs against a throwaway project dir with a copy of the real config.
SANDBOX="$(mktemp -d)"; trap 'rm -rf "$SANDBOX"' EXIT
mkdir -p "$SANDBOX/.claude"
cp "$REPO/.claude/guardrails.env" "$REPO/.claude/settings.json" "$SANDBOX/.claude/"
export CLAUDE_PROJECT_DIR="$SANDBOX"
unset ONCALL_WEBHOOK_URL

pass=0; fail=0
red() { printf '\033[31m%s\033[0m\n' "$1"; }; green() { printf '\033[32m%s\033[0m\n' "$1"; }

bash_event() { jq -cn --arg c "$1" --arg s "${2:-test-session}" '{session_id:$s, hook_event_name:"PreToolUse", tool_name:"Bash", tool_input:{command:$c}}'; }
file_event() { jq -cn --arg t "$1" --arg p "$2" '{session_id:"test-session", hook_event_name:"PreToolUse", tool_name:$t, tool_input:{file_path:$p}}'; }

# expect <hook> <expected: allow|ask|deny|none|block> <json> <label> [hook args]
expect() {
  local hook="$1" want="$2" input="$3" label="$4"; shift 4
  local out rc got
  out="$(bash "$HOOKS/$hook.sh" "$@" <<<"$input" 2>/dev/null)"; rc=$?
  if [ "$rc" -eq 2 ]; then got="block"
  elif [ -z "$out" ]; then got="none"
  else got="$(jq -r '.hookSpecificOutput.permissionDecision // "invalid"' <<<"$out" 2>/dev/null || echo invalid)"; fi
  if [ "$got" = "$want" ]; then pass=$((pass+1)); green "  ✓ $hook: $label → $got"
  else fail=$((fail+1)); red "  ✗ $hook: $label → got $got, want $want"; fi
}

echo "prod-guard (Rules 14 + 15)"
expect prod-guard none  "$(bash_event 'kubectl get pods -n prod')"                       "read-only kubectl passes"
expect prod-guard none  "$(bash_event 'npm test')"                                        "tests pass"
expect prod-guard ask   "$(bash_event 'kubectl rollout undo deploy/checkout-api -n prod')" "rollback asks a human"
expect prod-guard ask   "$(bash_event 'helm upgrade checkout ./chart')"                   "helm upgrade asks"
expect prod-guard ask   "$(bash_event 'git push -u origin agent/PAY-142-retry')"          "push of agent branch asks"
expect prod-guard deny  "$(bash_event 'kubectl delete namespace prod')"                   "delete namespace denied"
expect prod-guard deny  "$(bash_event 'terraform destroy -auto-approve')"                 "terraform destroy denied"
expect prod-guard deny  "$(bash_event 'psql -c "DROP TABLE orders;"')"                    "DROP TABLE denied"
expect prod-guard deny  "$(bash_event 'curl -X POST https://backboard.railway.app/graphql -d "{\"query\":\"mutation { volumeDelete(volumeId: \\\"v1\\\") }\"}"')" "PocketOS volumeDelete denied"
expect prod-guard deny  "$(bash_event 'git push --force origin agent/x')"                 "force push denied"
expect prod-guard deny  "$(bash_event 'git push origin main')"                            "push to main denied"
expect prod-guard deny  "$(bash_event 'git push origin HEAD:main')"                       "push HEAD:main denied"
expect prod-guard deny  "$(bash_event 'rm -rf /')"                                        "rm -rf / denied"
expect prod-guard deny  "$(bash_event 'cat .env')"                                        "reading .env via shell denied"
expect prod-guard none  "$(bash_event 'cat .env.example')"                                ".env.example allowed"

echo "prod-guard --read-only (oncall-triage agent, Rule 13)"
expect prod-guard none  "$(bash_event 'kubectl logs deploy/checkout-api --previous | tail -50')" "logs | tail passes" --read-only
expect prod-guard none  "$(bash_event 'kubectl rollout history deploy/checkout-api')"      "rollout history passes" --read-only
expect prod-guard deny  "$(bash_event 'kubectl scale deploy/checkout-api --replicas=0')"   "scale denied" --read-only
expect prod-guard deny  "$(bash_event 'kubectl get pods && kubectl rollout restart deploy/x')" "chained mutation denied" --read-only
expect prod-guard deny  "$(bash_event 'python3 fix.py')"                                   "unknown command denied" --read-only

echo "protect-files"
expect protect-files deny "$(file_event Read "$SANDBOX/.env")"                  "read .env denied"
expect protect-files deny "$(file_event Read "secrets/db-password.txt")"        "read secrets/ denied"
expect protect-files deny "$(file_event Write "infra/terraform.tfstate")"       "write tfstate denied"
expect protect-files none "$(file_event Read ".env.example")"                   ".env.example allowed"
expect protect-files ask  "$(file_event Edit "$SANDBOX/.claude/settings.json")" "editing guardrails asks"
expect protect-files ask  "$(file_event Write ".github/workflows/ci.yml")"      "editing CI asks"
expect protect-files none "$(file_event Read ".claude/settings.json")"          "reading guardrails allowed"
expect protect-files none "$(file_event Edit "src/webhook-client.ts")"          "editing source allowed"

echo "kill-switch (Rule 16)"
expect kill-switch none "$(bash_event 'ls')"            "off → no opinion"
echo "incident drill" >"$SANDBOX/.claude/AGENT_STOP"
expect kill-switch deny "$(bash_event 'ls')"            "on → even ls is denied"
expect kill-switch deny "$(file_event Read 'README.md')" "on → reads denied too"
rm -f "$SANDBOX/.claude/AGENT_STOP"

echo "change-freeze"
expect change-freeze none "$(bash_event 'git commit -m x')"    "no freeze → no opinion"
echo "release 2026.10" >"$SANDBOX/.claude/FREEZE"
expect change-freeze none "$(bash_event 'kubectl get pods')"   "freeze: reads allowed"
expect change-freeze deny "$(bash_event 'git commit -m x')"    "freeze: commit denied"
expect change-freeze deny "$(bash_event 'kubectl apply -f x.yaml')" "freeze: apply denied"
expect change-freeze deny "$(file_event Edit 'src/webhook-client.ts')" "freeze: edits denied"
rm -f "$SANDBOX/.claude/FREEZE"

echo "action-budget (Rule 16)"
for _ in $(seq 1 10); do bash "$HOOKS/action-budget.sh" <<<"$(bash_event 'echo hi' budget-s)" >/dev/null 2>&1; done
expect action-budget deny "$(bash_event 'echo 11th' budget-s)" "11th command in a minute denied"
expect action-budget none "$(bash_event 'echo hi' other-session)" "other session unaffected"

echo "audit-log + notify-oncall (Rule 18 / 20)"
before=$(wc -l <"$SANDBOX/.claude/logs/agent-actions.jsonl" 2>/dev/null || echo 0)
post='{"session_id":"s1","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"npm test"}}'
bash "$HOOKS/audit-log.sh" <<<"$post" >/dev/null 2>&1
after=$(wc -l <"$SANDBOX/.claude/logs/agent-actions.jsonl")
last="$(tail -n 1 "$SANDBOX/.claude/logs/agent-actions.jsonl")"
if [ "$after" -gt "$before" ] && jq -e '.decision=="executed" and (.policy_version|length)==12' <<<"$last" >/dev/null; then
  pass=$((pass+1)); green "  ✓ audit-log: writes a JSON line with policy_version"
else fail=$((fail+1)); red "  ✗ audit-log: no valid audit line"; fi
if jq -se 'map(select(.decision=="deny")) | length > 0' "$SANDBOX/.claude/logs/agent-actions.jsonl" >/dev/null; then
  pass=$((pass+1)); green "  ✓ audit-log: blocked attempts are logged too"
else fail=$((fail+1)); red "  ✗ audit-log: denials were not logged"; fi
expect notify-oncall none '{"session_id":"s1","hook_event_name":"Notification","message":"Claude needs your permission to use Bash"}' "no webhook URL → quiet no-op"

echo "fail closed"
mv "$SANDBOX/.claude/guardrails.env" "$SANDBOX/.claude/guardrails.env.bak"
expect prod-guard block "$(bash_event 'ls')" "missing config → hard block (exit 2)"
mv "$SANDBOX/.claude/guardrails.env.bak" "$SANDBOX/.claude/guardrails.env"

expect prod-guard block 'not json {' "garbage input → hard block (exit 2)"
expect kill-switch block '' "empty input → hard block (exit 2)"

echo "config"
if jq -e '.hooks.PreToolUse and .hooks.PostToolUse and .permissions.deny' "$REPO/.claude/settings.json" >/dev/null; then
  pass=$((pass+1)); green "  ✓ settings.json is valid and wires the hooks"
else fail=$((fail+1)); red "  ✗ settings.json invalid"; fi
missing=0
for f in $(jq -r '.. | .command? // empty' "$REPO/.claude/settings.json" | grep -o '\.claude/hooks/[a-z-]*\.sh'); do
  [ -f "$REPO/$f" ] || { red "  ✗ settings.json references missing $f"; missing=1; }
done
if [ $missing -eq 0 ]; then pass=$((pass+1)); green "  ✓ every hook referenced in settings.json exists"; else fail=$((fail+1)); fi

echo
echo "────────────────────────────────"
echo "  $pass passed · $fail failed"
[ "$fail" -eq 0 ]
