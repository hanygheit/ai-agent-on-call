// PAY-142 · Retry transient webhook failures (see docs/specs/PAY-142.md, ADR 0007).
// Retry on 5xx, timeouts and network errors. Never on 4xx.
// Backoff 200 ms × 2 (200 → 400 → 800). Max 4 attempts. Then throw.

export type FetchLike = (url: string, init: RequestInit) => Promise<{ status: number }>;

export interface RetryOptions {
  maxAttempts?: number;         // default 4
  baseDelayMs?: number;         // default 200
  timeoutMs?: number;           // per attempt, default 3000
  fetchImpl?: FetchLike;        // injected for tests
  sleep?: (ms: number) => Promise<void>;
}

export class WebhookDeliveryError extends Error {
  readonly attempts: number;
  readonly lastStatus: number | undefined;
  constructor(message: string, attempts: number, lastStatus: number | undefined) {
    super(message);
    this.name = 'WebhookDeliveryError';
    this.attempts = attempts;
    this.lastStatus = lastStatus;
  }
}

const defaultSleep = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms));

export async function sendPaymentWebhook(
  url: string,
  payload: unknown,
  opts: RetryOptions = {},
): Promise<{ status: number; attempts: number }> {
  const maxAttempts = opts.maxAttempts ?? 4;
  const baseDelayMs = opts.baseDelayMs ?? 200;
  const timeoutMs = opts.timeoutMs ?? 3000;
  const doFetch: FetchLike = opts.fetchImpl ?? ((u, init) => fetch(u, init));
  const sleep = opts.sleep ?? defaultSleep;

  let lastStatus: number | undefined;
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      const res = await doFetch(url, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify(payload),
        signal: AbortSignal.timeout(timeoutMs),
      });
      lastStatus = res.status;
      if (res.status < 400) return { status: res.status, attempts: attempt };
      if (res.status < 500) {
        // 4xx: the request is wrong. Retrying would duplicate side effects.
        throw new WebhookDeliveryError(`Client error ${res.status}; not retrying`, attempt, res.status);
      }
      // 5xx: transient, fall through to retry.
    } catch (err) {
      if (err instanceof WebhookDeliveryError) throw err;
      lastStatus = undefined; // timeout or network error: transient, retry.
    }
    if (attempt < maxAttempts) await sleep(baseDelayMs * 2 ** (attempt - 1));
  }
  throw new WebhookDeliveryError(
    `Webhook delivery failed after ${maxAttempts} attempts`,
    maxAttempts,
    lastStatus,
  );
}
