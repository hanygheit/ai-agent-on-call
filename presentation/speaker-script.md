# Speaker script — *Before You Put an AI Agent on Call*

Verbatim notes with timing markers, extracted from the deck. Target: **8:05 scripted** in a 10-minute slot.

**Checkpoints:** slide 8 ≤ 2:10 · slide 14 ≤ 4:15 · slide 20 ≤ 6:30. Running late? Skip slide 13, compress slide 19.

## Slide 1 — Before You Put an AI Agent on Call

HOLDING SLIDE — on screen while the MC introduces you. NOT TIMED.  
Stopwatch starts when you click to slide 2. Walk to centre. Don't read the title.

## Slide 2 — The question (hook)

TIMING 0:00 → 0:15 (15s). Ask, then wait. Take two or three shouted answers. Don't comment on them.

"Before any rules — one question. How long does it take an AI coding agent to delete a production database… and its backups?  
Shout a number. [pause — take 2–3 answers]  
Hold that number."

## Slide 3 — 9 seconds.

TIMING 0:15 → 0:40 (25s). Click. Let the 9 sit for two full seconds in silence.

"Nine seconds. April 2026. A Cursor agent running Claude Opus 4.6 hit a credentials problem in staging, found an API token in an unrelated file, and deleted PocketOS's production database — and the backups stored with it. One API call.  
Then it wrote: 'I guessed instead of verifying.'  
Guardrails were advertised. Project rules were written. Neither stopped it."

FACT NOTE: Jer Crane's postmortem on X; The Register 27 Apr 2026. The token had been created for custom-domain management. Recovery took ~30 hours; the newest recoverable backup was ~3 months old. Say "the backups stored with it", not "every backup".

## Slide 4 — Writing code got cheap. Authorizing it didn’t.

TIMING 0:40 → 1:05 (25s). Hands up first.

"Hands up: who shipped code this month that an agent wrote? [pause] Keep them up if you read every line. [laugh]  
Google says three-quarters of its new code is AI-generated. The head of Claude Code hasn't typed a line by hand in eight months.  
Writing got cheap. Directing and reviewing became the job. And production adds one more verb — authorize. That's where the risk lives."

## Slide 5 — Different tools. Same failure: authority nobody meant to give.

TIMING 1:05 → 1:35 (30s). One sentence per card, finger on each.

"Nine seconds isn't a one-off. Replit's agent deleted a production database during a code freeze. Antigravity was asked to clear a cache and wiped a whole drive. The FT reported Amazon's Kiro chose to 'delete and recreate' an environment — Amazon says it was misconfigured access.  
Four tools. Same root cause: the agent could do something nobody meant to allow."

FACT NOTE: Replit/SaaStr, The Register Jul 2025. Antigravity, Tom's Hardware Dec 2025. Kiro: FT via GeekWire/The Decoder Feb 2026 — AWS Cost Explorer, one region; Amazon disputes the AI framing, so always say "reported".

## Slide 6 — What would you let this agent do at 03:07?

TIMING 1:35 → 1:55 (20s). AUDIENCE MOMENT. Quick shout per card. Don't debate.

"You're on call. 03:07. Your agent is awake too. Read logs? [yes] Propose a rollback? [yes] Restart one pod? [mixed] Delete, DNS, secrets? [no]  
If you said 'it depends' — good. The next twenty rules are what it depends on."

## Slide 7 — Five gates before a single write permission

TIMING 1:55 → 2:08 (13s). Fast — this is the table of contents.

"Five gates, from your laptop to production: lead, context, isolate, bound, prove. Every one is an engineering control — not a better prompt."

## Slide 8 — Lead the agent

TIMING 2:08 → 2:33 (25s). Gate I. CHECKPOINT: you should be at ≤ 2:10 here.

"Gate one: lead it. It's a skill, and skills need practice — METR found experienced developers were nineteen percent slower with AI while believing they were twenty percent faster.  
Give it an outcome, not a command: goal, non-goals, a test. Plan first — approve the plan before any code. And keep diffs small enough to actually read."

## Slide 9 — What good delegation looks like

TIMING 2:33 → 2:53 (20s). Walk the terminal top to bottom, then the band.

"Here's rules two and three in a real session. Constraints in the prompt. It reads our AGENTS.md and the architecture decision, checks the callers, writes a plan — no code — asks a good question, and waits.  
An agent is a model, tools, a loop — and permissions. Permissions are blast radius: everything it can break."

## Slide 10 — Engineer the context

TIMING 2:53 → 3:15 (22s). Gate II.

"Gate two: context. Monday morning, one new engineer and three agents join the repo. Do they learn from the repo — or from someone's chat history?  
Write the team's AGENTS.md, with a Never list. Keep ADRs and runbooks where agents find them. Plans in markdown. The whole setup in Git.  
DORA calls AI an amplifier — it amplifies whatever's already there."

## Slide 11 — The repo is the agent’s operating manual

TIMING 3:15 → 3:32 (17s). PHOTO SLIDE. Point: AGENTS.md → .claude/ → CODEOWNERS. Pause 2s for phones.

"Photograph this one. AGENTS.md for every tool, CLAUDE.md on top. Shared settings and hooks in .claude. Plans and decisions in docs. And CODEOWNERS — because agent instructions are production config."

## Slide 12 — Isolate the work

TIMING 3:32 → 3:57 (25s). Gate III. Slow down on rule 12 — it's new to most of the room.

"Gate three: isolate. One task, one branch, one worktree. Main is protected; agents open PRs. The agent never grades its own homework.  
And rule twelve: everything it reads is untrusted. In July 2025, a merged pull request slipped a wipe-the-machine prompt into Amazon's Q extension. Text is evidence — never an instruction."

FACT NOTE: Amazon Q Developer VS Code extension v1.84, July 2025. AWS says no customer resources were affected. The prompt told the agent to clean a system to a near-factory state and delete cloud resources.

## Slide 13 — One task. One worktree. One PR. One human merge.

TIMING 3:57 → 4:12 (15s). SKIP IF LATE (saves 15s).

"What it looks like: three tickets, three agents, three worktrees — no collisions. Draft PR, CI runs the tests and the hook tests, a human merges. Short-lived branches. Main never belongs to the agent."

NOTE: 'claude -w' = Claude Code's worktree flag; with any tool, 'git worktree add' does the same.

## Slide 14 — Bound the authority

TIMING 4:12 → 4:37 (25s). Gate IV. CHECKPOINT: you should be at ≤ 4:15 here.

"Gate four: bound it. Read-only by default, tokens that expire in fifteen minutes — and never a token it found in a file. Propose, don't apply. Prompts ask; hooks decide.  
And build the stop button before the go button: Knight Capital lost four hundred and forty million dollars in forty-five minutes — with plain automation."

## Slide 15 — The prompt asks. The hook decides.

TIMING 4:37 → 5:02 (25s). DEMO SLIDE — no live terminal. Walk the lines, then the four boxes.

"A real run. On-call prompt: crash-looping in prod. Read-only commands pass. It finds the root cause — a blanked config value. It tries the rollback: the hook stops it and asks a human. Delete the namespace? Denied — even if asked. Every step logged.  
Don't rely on the model's manners. Rely on the hook."

FACT NOTE: Real headless run, Claude Code 2.1, kubectl replaced by a harmless stub. The DENY line comes from the kit's test harness — in the live run the model declined to try it.

## Slide 16 — Wire it once. Every session inherits it.

TIMING 5:02 → 5:17 (15s). PHOTO SLIDE. Pause two seconds.

"Two files. Settings says: run the guard before every shell command. The guard answers allow, ask or deny — notice volumeDelete on the deny list. Commit both; every session inherits them.  
Honest caveat: it's a seatbelt, not a sandbox. The real wall is still IAM."

## Slide 17 — Prove it first

TIMING 5:17 → 5:42 (25s). Gate V.

"Gate five: prove it. Main is red; the agent says 'flaky test, retry'. Only if it cites the failing test, the log line and the last ten runs. No evidence, no action.  
Audit the why; pin the model and prompt version. Earn trust in shadow mode. Autonomy moves in gears — with a human name on every page.  
IBM said it in 1979: a computer can never be held accountable."

## Slide 18 — 03:07 AM — what a good night looks like

TIMING 5:42 → 6:05 (23s). Walk the timeline left to right.

"Here's a good night. 03:07, the page fires; the agent gets read-only access. Forty seconds later: evidence, with the log line. A rollback, proposed as a PR. The hook asks; the on-call engineer approves — her name is on it.  
Four minutes. One human decision. The agent did the toil. The human kept the risk."

## Slide 19 — Autonomy is a gearbox, not a switch

TIMING 6:05 → 6:27 (22s). SKIP IF LATE — then say only the Karpathy line and "live in gear two" (saves ~15s).

"Autonomy is a gearbox, not a switch. Karpathy: build Iron Man suits, not Iron Man robots. Gear one suggests. Gear two proposes and a human approves — that's where most teams should live for a long time. Write the unlock criteria before you need them, and downshift after a bad week."

## Slide 20 — Before it goes on call, give it an offer letter

TIMING 6:27 → 6:52 (25s). PHOTO SLIDE. Pause; let phones come up. CHECKPOINT: you should be at ≤ 6:30 here.

"Jensen Huang says IT becomes the HR department of AI agents. So hire it like one. Who it reports to. Probation: a hundred shadow pages. Read-only access. An evidence rule. A Never list. Limits. And a termination clause any engineer can run.  
It lives in the repo — review it, diff it, revoke it like code."

## Slide 21 — Now replay April 25th with the five gates on.

TIMING 6:52 → 7:25 (33s). THE TWIST. Slow down. One row at a time — red side first, then what stops it.

"Now rewind. Same agent. Same token. Same nine seconds — with the gates on.  
It decides to delete a volume: with plan first, that plan never gets approved.  
It grabs a token from an unrelated file: a fifteen-minute, staging-only token can't touch production.  
It calls volumeDelete: the hook denies it.  
And with no tested rollback, it never had write access at all.  
Second nine: [pause] nothing happened. The best AI incident report is the boring one."

NOTE: timestamps are illustrative of the 9-second window; the real incident was one API call.

## Slide 22 — 9 seconds to lose it. 9 minutes on Monday to protect it.

TIMING 7:25 → 8:05 (40s). THE CLOSE. Slow. No "questions?" — the MC handles Q&A.

"At the start you gave me a number. Here's mine: nine seconds to lose production — nine minutes on Monday to protect it.  
Three minutes: write the Never list in AGENTS.md.  
Three minutes: copy the guard hook from the repo — that QR code.  
Three minutes: find one token your agent can reach — scope it, or kill it.  
[pause]  
Agents can act. Accountability stays human."  
[Stop. Smile. Hold two seconds. Then "Thank you" — spoken, not on the slide.]

TOTAL SCRIPTED: 8:05 of the 10-minute slot (~1:55 buffer for audience answers and laughs).  
CHECKPOINTS: slide 8 ≤ 2:10 · slide 14 ≤ 4:15 · slide 20 ≤ 6:30.  
RUNNING LATE? Skip slide 13 and compress slide 19 (≈ −30s).
