# The talk: *Before You Put an AI Agent on Call*

**20 Rules for Safe Production Autonomy** · Ignite talk · DevOpsDays Cairo 2026 · Hany Saad

| File | What |
|---|---|
| [`…DevOpsDays-Cairo-2026.pdf`](Before-You-Put-an-AI-Agent-on-Call-DevOpsDays-Cairo-2026.pdf) | Read the slides in the browser |
| [`…DevOpsDays-Cairo-2026.pptx`](Before-You-Put-an-AI-Agent-on-Call-DevOpsDays-Cairo-2026.pptx) | Original deck with speaker notes |
| [`speaker-script.md`](speaker-script.md) | Verbatim script with timing markers (8:05 scripted) |

## The talk in one paragraph

In April 2026 a coding agent deleted a company's production database — and the
backups stored with it — in **9 seconds**, with one API call. Guardrails were
advertised and project rules were written; neither stopped it. The fix is not a
better prompt. It is **five gates** — Lead, Context, Isolate, Bound, Prove — made of
**twenty engineering controls**, every one of which is implemented in this repo.

## Slide → repo map

| Slide | Topic | Look at |
|---|---|---|
| 8 | Gate I · Lead (rules 01–04) | [`.claude/skills/plan-feature`](../.claude/skills/plan-feature/SKILL.md), [`docs/specs/PAY-142.md`](../docs/specs/PAY-142.md) |
| 9 | A real planning session | [`docs/specs/PAY-142.md`](../docs/specs/PAY-142.md), [`docs/adr/0007…`](../docs/adr/0007-webhook-retry-policy.md) |
| 10–11 | Gate II · Context, repo structure | [`AGENTS.md`](../AGENTS.md), [`CLAUDE.md`](../CLAUDE.md), [`.github/CODEOWNERS`](../.github/CODEOWNERS) |
| 12–13 | Gate III · Isolate, branching | [`scripts/protect-main.sh`](../scripts/protect-main.sh), [`ci.yml`](../.github/workflows/ci.yml) |
| 14–16 | Gate IV · Bound, the hooks demo | [`.claude/settings.json`](../.claude/settings.json), [`.claude/hooks/`](../.claude/hooks/), [`guardrails.env`](../.claude/guardrails.env) |
| 17–19 | Gate V · Prove, gearbox | [`audit-log.sh`](../.claude/hooks/audit-log.sh), [`ops/agent-offer-letter.yaml`](../ops/agent-offer-letter.yaml) |
| 20 | The offer letter | [`ops/agent-offer-letter.yaml`](../ops/agent-offer-letter.yaml) |
| 21 | The rewind (PocketOS replayed) | `volumeDelete` in [`guardrails.env`](../.claude/guardrails.env) |
| 22 | Your next 9 minutes | [Quick start](../README.md#-your-next-9-minutes) |

## Sources cited in the talk

PocketOS: Jer Crane's postmortem via The Register (27 Apr 2026), NeuralTrust and SmarterX analyses ·
Replit/SaaStr: The Register (Jul 2025) · Google Antigravity: Tom's Hardware (Dec 2025) ·
AWS Kiro: Financial Times via GeekWire / The Decoder (Feb 2026; Amazon disputes the AI framing) ·
Amazon Q extension: Tom's Hardware / SC Media (Jul 2025) · Google 75%: Google blog (22 Apr 2026) ·
Microsoft 20–30%: Nadella at LlamaCon (Apr 2025) · Boris Cherny: Fortune Brainstorm Tech (Jun 2026) ·
METR productivity study (Jul 2025) · DORA State of AI-assisted Software Development (Sep 2025) ·
Simon Willison, "The lethal trifecta" (Jun 2025) · Knight Capital: SEC press release 2013-222 ·
Karpathy, YC AI Startup School (Jun 2025) · Jensen Huang, CES (Jan 2025) · IBM training slide (1979).
