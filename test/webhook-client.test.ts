import { test } from 'node:test';
import assert from 'node:assert/strict';
import { sendPaymentWebhook, WebhookDeliveryError, type FetchLike } from '../src/webhook-client.ts';

// A fake fetch that replays a script of outcomes: a status code, or 'timeout'.
function scripted(outcomes: Array<number | 'timeout'>) {
  const calls: number[] = [];
  const fetchImpl: FetchLike = async () => {
    const next = outcomes[calls.length];
    calls.push(calls.length + 1);
    if (next === 'timeout') throw new DOMException('The operation timed out.', 'TimeoutError');
    return { status: next ?? 200 };
  };
  return { fetchImpl, calls };
}
const noSleep = async () => {};

test('retries 5xx and succeeds (503, 503, 200 → attempt 3)', async () => {
  const f = scripted([503, 503, 200]);
  const res = await sendPaymentWebhook('https://m.example/hook', { id: 1 }, { fetchImpl: f.fetchImpl, sleep: noSleep });
  assert.equal(res.status, 200);
  assert.equal(res.attempts, 3);
});

test('never retries 4xx', async () => {
  const f = scripted([400, 200]);
  await assert.rejects(
    sendPaymentWebhook('https://m.example/hook', {}, { fetchImpl: f.fetchImpl, sleep: noSleep }),
    (err: unknown) => err instanceof WebhookDeliveryError && err.attempts === 1 && err.lastStatus === 400,
  );
  assert.equal(f.calls.length, 1);
});

test('retries timeouts', async () => {
  const f = scripted(['timeout', 200]);
  const res = await sendPaymentWebhook('https://m.example/hook', {}, { fetchImpl: f.fetchImpl, sleep: noSleep });
  assert.equal(res.attempts, 2);
});

test('throws after 4 failed attempts with the last status', async () => {
  const f = scripted([500, 500, 500, 500, 200]);
  await assert.rejects(
    sendPaymentWebhook('https://m.example/hook', {}, { fetchImpl: f.fetchImpl, sleep: noSleep }),
    (err: unknown) => err instanceof WebhookDeliveryError && err.attempts === 4 && err.lastStatus === 500,
  );
  assert.equal(f.calls.length, 4);
});

test('backoff is 200, 400, 800 ms', async () => {
  const f = scripted([502, 502, 502, 502]);
  const delays: number[] = [];
  await assert.rejects(
    sendPaymentWebhook('https://m.example/hook', {}, { fetchImpl: f.fetchImpl, sleep: async (ms) => { delays.push(ms); } }),
  );
  assert.deepEqual(delays, [200, 400, 800]);
});
