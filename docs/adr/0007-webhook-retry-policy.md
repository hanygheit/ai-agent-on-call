# 0007: Webhook retry policy

- **Status:** Accepted
- **Date:** 2026-06-10
- **Deciders:** payments team

## Context
Merchant endpoints fail transiently (deploys, cold starts, load balancers). Retrying
client errors (4xx) creates duplicate side effects and hides real bugs.

## Decision
- Retry **only** on HTTP 5xx, timeouts and network errors. **Never** retry 4xx.
- Exponential backoff starting at **200 ms, factor 2**. **Max 4 attempts** in-process.
- Per-attempt timeout: 3 s.
- After the last attempt, raise an error so the caller can dead-letter the event.
- No new dependency for this.

## Consequences
- Worst-case in-process delay ≈ 1.4 s of backoff + 4 × timeout.
- Longer retries (minutes/hours) belong in a queue, not in the client.
