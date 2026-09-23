# The 20 rules — and where each one lives in this repo

From the DevOpsDays Cairo 2026 talk *"Before You Put an AI Agent on Call"*.
Every rule is an engineering control, not a better prompt.

| # | Rule | Implemented by |
|---|---|---|
| **Gate I · Lead** — *Who is leading?* | | |
| 01 | Train it like a skill: start low-risk, measure, don't feel | Team practice · `ops/agent-offer-letter.yaml` (start in Gear 1) |
| 02 | Give an outcome, not a command | `AGENTS.md` → *How we work* · `docs/specs/_TEMPLATE.md` |
| 03 | Plan first. Approve. Then code | `.claude/skills/plan-feature/` · `docs/specs/PAY-142.md` |
| 04 | Small diffs. Read every one | `AGENTS.md` · `.github/pull_request_template.md` |
| **Gate II · Context** — *What does it know?* | | |
| 05 | Write the team's AGENTS.md (with a Never list) | `AGENTS.md` · `CLAUDE.md` imports it |
| 06 | Make architecture discoverable | `docs/adr/` · `docs/runbooks/` |
| 07 | Plans live in .md, not in chat | `docs/specs/` |
| 08 | Version the agent setup in Git | `.claude/` committed · `.github/CODEOWNERS` · CI |
| **Gate III · Isolate** — *Where does its work land?* | | |
| 09 | One task, one branch, one worktree | `AGENTS.md` · `CLAUDE.md` (`claude --worktree`) |
| 10 | Main is protected. Agents open PRs | `scripts/protect-main.sh` · deny rules in `settings.json` · `prod-guard.sh` |
| 11 | It never grades its own homework | `.github/workflows/ci.yml` (independent tests + guardrail tests) |
| 12 | Everything it reads is untrusted | `AGENTS.md` → *Untrusted input* · `oncall-triage` agent |
| **Gate IV · Bound** — *What can it touch?* | | |
| 13 | Read-only first. Short-lived tokens | `oncall-triage` + `prod-guard.sh --read-only` · offer letter `access` |
| 14 | Propose, don't apply | `prod-guard.sh` ASK list · runbooks split *investigate / decide / apply* |
| 15 | Prompts ask. Hooks decide | `.claude/settings.json` + `.claude/hooks/*` + `.claude/guardrails.env` |
| 16 | Build the stop button first | `kill-switch.sh` + `ops/agent-stop.sh` · `action-budget.sh` · `change-freeze.sh` |
| **Gate V · Prove** — *Has it earned more?* | | |
| 17 | No evidence, no action | `AGENTS.md` · `oncall-triage` output format |
| 18 | Audit the why. Pin the versions | `audit-log.sh` → `.claude/logs/agent-actions.jsonl` (with `policy_version`) |
| 19 | Earn it in shadow mode | offer letter `probation` + `review` metrics |
| 20 | Autonomy in gears. A human owns it | offer letter `gear`, `reports_to` · `notify-oncall.sh` |

## What hooks can and cannot do

Hooks are a **seatbelt, not a sandbox**. They pattern-match commands and paths before
a tool runs in Claude Code sessions on this checkout. A determined or creative agent
can phrase a command the patterns don't catch. The outer wall is always:

- **IAM / RBAC**: the agent's credentials physically cannot do the dangerous thing.
- **Short-lived, scoped tokens** issued per task (never a token found in a file).
- **Platform policy** (admission controllers, SCPs, branch protection).
- **Separate failure domains for backups** (PocketOS lost its backups with its volume).
