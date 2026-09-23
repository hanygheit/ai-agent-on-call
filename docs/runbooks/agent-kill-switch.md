# Runbook: stop all agents now (kill switch)

**Who can pull it:** any engineer, any time, no approval needed.
**When:** an agent is doing something unexpected, looping, touching the wrong
environment, or you simply are not sure.

## Stop
```bash
ops/agent-stop.sh "why you stopped it"
```
Creates `.claude/AGENT_STOP`. The `kill-switch` hook now denies **every** tool call
in every Claude Code session that uses this checkout. In-flight commands finish;
nothing new starts.

> Scope: hooks protect sessions running on this checkout. For agents running
> elsewhere (CI, cloud sessions, other tools) also **revoke their credentials** —
> that is the real outer wall.

## Then
1. Post in the incident channel: what you saw, when you stopped it.
2. Check the audit trail: `tail -n 50 .claude/logs/agent-actions.jsonl | jq .`
3. Revoke or rotate any token the agent could reach if anything looks wrong.

## Resume
```bash
ops/agent-start.sh
```
Only after the cause is understood. Consider downshifting a gear in
`ops/agent-offer-letter.yaml`.

## Change freeze (softer)
```bash
ops/freeze.sh on "release 2026.10"   # read/investigate only
ops/freeze.sh off
```
