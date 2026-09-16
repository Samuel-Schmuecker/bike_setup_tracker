import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createDeleteHandler } from './handler.mjs';

const url = 'https://project.supabase.co';
function fixture({ invalid = false, storageError = false, missing = false,
  anonymous = false, claimError = false, sourceRegistered = false } = {}) {
  const calls = [];
  let batches = 0;
  const admin = {
    auth: {
      getClaims: async () => ({ data: { claims: { sub: 'own-id', role: 'authenticated', iss: url + '/auth/v1' } }, error: invalid ? {} : null }),
      getUser: async () => ({ data: { user: { id: 'own-id', is_anonymous: anonymous, identities: anonymous ? [] : [{ provider: 'google' }] } } }),
      admin: {
        getUserById: async (id) => { calls.push(['lookup', id]); return missing ? { error: { status: 404 } } : { data: { user: { id, is_anonymous: id === 'guest-id' && !sourceRegistered } } }; },
        deleteUser: async (id) => { calls.push(['delete', id]); return {}; },
      },
    },
    rpc: async (name, args) => {
      calls.push([name, args.p_user_id]);
      if (name === 'prepare_guest_transfer') return { data: 'ticket' };
      if (name === 'claim_guest_transfer') {
        calls.push(['target', args.p_target]);
        return { data: 'guest-id', error: claimError ? {} : null };
      }
      return { data: name === 'account_deletion_images' && batches++ === 0 ? [{ name: 'own-id/nested/photo' }] : [] };
    },
    storage: { from: () => ({ remove: async (names) => { calls.push(['images', names]); return { error: storageError ? {} : null }; } }) },
  };
  return { calls, handler: createDeleteHandler(() => admin, url) };
}
const request = (token = 'valid', body = { confirm: 'DELETE', user_id: 'victim-id' }) => new Request(url, {
  method: 'POST', headers: token ? { Authorization: `Bearer ${token}` } : {}, body: JSON.stringify(body),
});
test('rejects missing or invalid credentials before mutations', async () => {
  for (const token of ['', 'invalid']) {
    const { handler, calls } = fixture({ invalid: true });
    assert.equal((await handler(request(token))).status, 401);
    assert.deepEqual(calls, []);
  }
});
test('requires confirmation and ignores caller-supplied target UID', async () => {
  const denied = fixture();
  assert.equal((await denied.handler(request('valid', {}))).status, 400);
  assert.equal(denied.calls.length, 1);
  const { handler, calls } = fixture();
  assert.equal((await handler(request())).status, 200);
  assert.deepEqual(calls.at(-1), ['delete', 'own-id']);
  assert.deepEqual(calls.find(([name]) => name === 'images'), ['images', ['own-id/nested/photo']]);
  assert.ok(calls.findIndex(([name]) => name === 'begin_account_deletion') < calls.findIndex(([name]) => name === 'images'));
});
test('storage failure retains account for retry', async () => {
  const { handler, calls } = fixture({ storageError: true });
  assert.equal((await handler(request())).status, 500);
  assert.ok(!calls.some(([name]) => name === 'delete'));
});
test('retry after successful deletion returns success for verified own UID', async () => {
  const { handler, calls } = fixture({ missing: true });
  assert.deepEqual(await (await handler(request())).json(), { deleted: true });
  assert.deepEqual(calls, [['lookup', 'own-id']]);
});

test('only anonymous users can prepare a guest transfer', async () => {
  const body = { action: 'prepare_guest', revisions: {} };
  assert.equal((await fixture().handler(request('valid', body))).status, 403);
  const guest = fixture({ anonymous: true });
  assert.deepEqual(await (await guest.handler(request('valid', body))).json(), { ticket: 'ticket' });
  assert.ok(!guest.calls.some(([name]) => name === 'delete'));
});
test('guest cleanup uses server-authorized source and verified target', async () => {
  const { handler, calls } = fixture();
  const response = await handler(request('valid', { action: 'finish_guest', confirm: 'DELETE', ticket: 'ticket', source: 'victim' }));
  assert.equal(response.status, 200);
  assert.deepEqual(calls.find(([name]) => name === 'target'), ['target', 'own-id']);
  assert.deepEqual(calls.at(-1), ['delete', 'guest-id']);
});
test('invalid ticket, changed source or anonymous target never delete anyone', async () => {
  for (const options of [{ claimError: true }, { sourceRegistered: true }, { anonymous: true }]) {
    const { handler, calls } = fixture(options);
    const response = await handler(request('valid', { action: 'finish_guest', confirm: 'DELETE', ticket: 'ticket' }));
    assert.ok([403, 409].includes(response.status));
    assert.ok(!calls.some(([name]) => name === 'delete' || name === 'images'));
  }
});
