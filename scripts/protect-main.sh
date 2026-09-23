#!/usr/bin/env bash
# protect-main.sh — Rule 10: main is protected; agents open PRs.
# Applies GitHub branch protection with the gh CLI (you must be a repo admin).
#
#   bash scripts/protect-main.sh hanygheit/ai-agent-on-call [branch]
#
# Requires: PR before merge, 1 approving review, CODEOWNER review,
# the CI checks "guardrails" and "tests", no force-pushes, no deletions.
set -euo pipefail
repo="${1:?usage: $0 <owner>/<repo> [branch]}"; branch="${2:-main}"
command -v gh >/dev/null || { echo "install the GitHub CLI: https://cli.github.com" >&2; exit 1; }

gh api -X PUT "repos/$repo/branches/$branch/protection" \
  -H "Accept: application/vnd.github+json" --input - <<JSON
{
  "required_status_checks": { "strict": true, "contexts": ["guardrails", "tests"] },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "require_code_owner_reviews": true,
    "dismiss_stale_reviews": true
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true
}
JSON
echo "🔒 $repo:$branch is protected (PR + CI + CODEOWNER review, no force-push)."
