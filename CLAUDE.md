# CLAUDE.md

@AGENTS.md

## Claude Code specifics

- **Planning:** use the `/plan-feature` skill for any non-trivial ticket. It writes
  `docs/specs/<ticket>.md` and stops for approval. Plan mode (Shift+Tab) is fine for
  exploration, but the approved plan must land in the repo, not only in chat.
- **Parallel work:** one worktree per task — `claude --worktree <ticket>`
  (or `git worktree add ../<ticket> -b agent/<ticket>-<slug>`).
- **Incidents:** delegate investigation to the `oncall-triage` subagent. It is
  read-only by design and ends with a proposal for a human.
- **Guardrails:** `.claude/settings.json` runs hooks before every tool call
  (kill switch, change freeze, protected files, prod-guard, action budget) and logs
  every action. A hook denial is final: explain what you were trying to do and ask
  the human. Never try an alternative command to get the same effect.
- **Personal settings** go in `.claude/settings.local.json` (gitignored), never in
  the shared `settings.json`.
