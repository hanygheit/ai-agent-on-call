#!/usr/bin/env bash
# shellcheck disable=SC2016  # perl expressions are single-quoted on purpose
# init-starter.sh — turn this starter into YOUR project in one command.
#
#   bash scripts/init-starter.sh <project-name> [--owner @org/team] [--keep-sample]
#
# - renames checkout-service → <project-name> in AGENTS.md, offer letter, package.json
# - sets CODEOWNERS to your team (default: keeps current owner)
# - removes the PAY-142 sample code, spec, ADR 0007 and sample runbook
#   (unless --keep-sample), leaving the templates and the guardrails in place
set -euo pipefail
cd "$(dirname "$0")/.."

name="${1:-}"; shift || true
[ -n "$name" ] || { echo "usage: $0 <project-name> [--owner @org/team] [--keep-sample]" >&2; exit 1; }
owner=""; keep=0
while [ $# -gt 0 ]; do
  case "$1" in
    --owner) owner="$2"; shift 2 ;;
    --keep-sample) keep=1; shift ;;
    *) echo "unknown option $1" >&2; exit 1 ;;
  esac
done

# portable in-place edit (GNU + BSD/macOS) via perl; single quotes are intentional
sub() { perl -pi -e "$1" "${@:2}"; }

# values go through the environment so slashes / @ in names are safe
export NAME="$name" OWNER="$owner"
sub 's/checkout-service/$ENV{NAME}/g' AGENTS.md ops/agent-offer-letter.yaml
sub 's/"name": "ai-agent-on-call"/"name": "$ENV{NAME}"/' package.json
if [ -n "$owner" ]; then sub 's/\@hanygheit/$ENV{OWNER}/g' .github/CODEOWNERS; fi

if [ "$keep" -eq 0 ]; then
  rm -f src/webhook-client.ts test/webhook-client.test.ts \
        docs/specs/PAY-142.md docs/adr/0007-webhook-retry-policy.md \
        docs/runbooks/checkout-api-rollback.md
  touch src/.gitkeep test/.gitkeep
  # keep `npm test` green until you add real tests
  node -e 'const f="package.json",p=JSON.parse(require("fs").readFileSync(f));p.scripts.test=p.scripts.test+" || echo \"no tests yet\"";require("fs").writeFileSync(f,JSON.stringify(p,null,2)+"\n")' 
  sub '$_ = "" if /Starter repo:\*\*|^> Replace them with|^>\s*$/' AGENTS.md
  sub 's/^- \*\*What:\*\*.*$/- **What:** <one line: what this service does>  <!-- CUSTOMIZE -->/; s/^- \*\*Stack:\*\*.*$/- **Stack:** <language, framework, runtime>  <!-- CUSTOMIZE -->/' AGENTS.md
fi

echo "✅ Initialised '$name'. Next:"
echo "   1. Edit the CUSTOMIZE lines in AGENTS.md (stack, commands)."
echo "   2. Tune .claude/guardrails.env for your platform (kubectl? terraform? cloud CLIs?)."
echo "   3. Fill in ops/agent-offer-letter.yaml (owner rotation, model id) and sign it."
echo "   4. bash scripts/test-hooks.sh   # guardrails still pass?"
echo "   5. bash scripts/protect-main.sh <owner>/<repo>   # branch protection (needs gh CLI)"
