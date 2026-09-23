# 0001: How coding agents work in this repository

- **Status:** Accepted
- **Date:** 2026-09-24
- **Deciders:** platform team

## Context
Coding agents write a growing share of our code and can run commands against real
systems. Public incidents (Replit, Jul 2025; PocketOS, Apr 2026) share one root
cause: the agent could do something nobody meant to allow. Instructions in a prompt
are not an enforcement boundary.

## Decision
We adopt the **five gates / twenty rules** operating model (see `docs/the-20-rules.md`):

1. **Lead** — outcome + plan + human approval before code; small diffs.
2. **Context** — team rules in `AGENTS.md`, decisions in ADRs, plans in `docs/specs/`.
3. **Isolate** — one task, one branch, one worktree; agents open PRs, never push to `main`.
4. **Bound** — read-only by default, short-lived scoped credentials, propose-don't-apply,
   guardrails enforced by hooks and IAM, kill switch + action budget.
5. **Prove** — evidence for every action, audit log with policy version, shadow mode,
   autonomy in gears with a named human owner.

Agent configuration (`.claude/`, `AGENTS.md`, `CLAUDE.md`, `ops/`) is production
configuration: CODEOWNERS-protected and tested in CI.

## Consequences
- Agents are slower to *start* a task (plan + approval) and faster to finish it safely.
- Hooks are a seatbelt, not a sandbox: IAM and platform policy remain the outer wall.
- Every change to guardrails needs a platform-team review.
