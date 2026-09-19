import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createCleanupHandler } from './handler.mjs';

const url = 'https://project.supabase.co';
function fixture({ invalid = false, missing = false, storageError = false,
  finishError = false, foreign = false, endless = false } = {}) {
  const calls = [];
  let finished = false;
  const admin = {
    auth: {
      getClaims: async () => ({ data: { claims: { sub: 'own-id', role: 'authenticated', iss: `${url}/auth/v1` } }, error: invalid ? {} : null }),
      getUser: async () => ({ data: { user: missing ? null : { id: 'own-id' } } }),
    },
    rpc: async (name, args) => {
      calls.push([name, args]);
      if (name === 'claim_bike_image_cleanup') return { data: finished && !endless ? [] : [{ name: `${foreign ? 'other-id' : 'own-id'}/photo` }] };
      if (finishError) return { error: {} };
      finished = true;
      return {};
    },
    storage: { from: (bucket) => ({ remove: async (names) => {
      calls.push(['remove', bucket, names]);
      return storageError ? { error: {} } : {};
    } }) },
  };
  return { calls, handler: createCleanupHandler(() => admin, url) };
}
const request = (token = 'valid') => new Request(url, {
  method: 'POST', headers: token ? { Authorization: `Bearer ${token}` } : {},
  body: JSON.stringify({ user_id: 'victim', names: ['victim/photo'] }),
});

test('invalid or deleted users cannot start cleanup', async () => {
  for (const options of [{ invalid: true }, { missing: true }]) {
    const { handler, calls } = fixture(options);
    assert.equal((await handler(request())).status, 401);
    assert.deepEqual(calls, []);
  }
  assert.equal((await fixture().handler(request(''))).status, 401);
});

test('uses only verified owner and server candidates, acknowledges after Storage removal', async () => {
  const { handler, calls } = fixture();
  assert.deepEqual(await (await handler(request())).json(), { complete: true });
  assert.deepEqual(calls, [
    ['claim_bike_image_cleanup', { p_user_id: 'own-id' }],
    ['remove', 'bike-images', ['own-id/photo']],
    ['finish_bike_image_cleanup', { p_user_id: 'own-id', p_names: ['own-id/photo'] }],
    ['claim_bike_image_cleanup', { p_user_id: 'own-id' }],
  ]);
});

test('Storage errors leave the job unacknowledged for retry', async () => {
  const { handler, calls } = fixture({ storageError: true });
  assert.equal((await handler(request())).status, 500);
  assert.ok(!calls.some(([name]) => name === 'finish_bike_image_cleanup'));
});

test('lost acknowledgement can retry the immutable old name', async () => {
  const { handler, calls } = fixture({ finishError: true });
  assert.equal((await handler(request())).status, 500);
  assert.equal((await handler(request())).status, 500);
  assert.equal(calls.filter(([name]) => name === 'remove').length, 2);
});

test('never removes a foreign object even if a broken RPC returns one', async () => {
  const { handler, calls } = fixture({ foreign: true });
  assert.equal((await handler(request())).status, 500);
  assert.ok(!calls.some(([name]) => name === 'remove'));
});

test('large batches remain visibly pending and resume on the next request', async () => {
  const { handler, calls } = fixture({ endless: true });
  const result = await handler(request());
  assert.equal(result.status, 202);
  assert.deepEqual(await result.json(), { complete: false });
  assert.equal(calls.filter(([name]) => name === 'remove').length, 5);
});
