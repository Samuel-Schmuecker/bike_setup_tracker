import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createCleanupHandler } from './handler.mjs';
const secret = 'test-secret-'.repeat(4);
function fixture({ dry = false, claimed = true, storageError = false } = {}) {
  const calls = []; let pages = 0;
  const query = (data) => {
    const q = { then: (resolve) => Promise.resolve({ data }).then(resolve) };
    for (const name of ['select','is','order','limit','eq']) q[name] = () => q;
    q.single = () => Promise.resolve({ data });
    q.update = (value) => { calls.push(['log',value]); return q; };
    return q;
  };
  const admin = {
    from: (table) => query(table === 'guest_cleanup_settings' ? { enabled:true, dry_run:dry, batch_size:20 } : []),
    rpc: (name) => {
      calls.push([name]);
      return query(name === 'preview_guest_cleanup' ? [{ user_id:'guest' }] : name === 'claim_guest_cleanup' ? claimed :
        name === 'account_deletion_images' ? (pages++ === 0 ? [{ name:'guest/nested/photo' }] : []) : null);
    },
    auth: { admin: {
      getUserById: async (uid) => ({ data:{ user:{ id:uid,is_anonymous:true } } }),
      deleteUser: async (uid) => { calls.push(['delete',uid]); return {}; },
    } },
    storage: { from: () => ({ remove: async (names) => { calls.push(['remove',names]); return { error:storageError }; } }) },
  };
  return { calls, handler:createCleanupHandler(() => admin,'https://example.supabase.co',secret) };
}
const request = (token=secret) => new Request('https://example.supabase.co',{ method:'POST',headers:{ 'x-cleanup-secret':token },body:'{"user_id":"victim","dry_run":false}' });
test('rejects unauthorized calls before accessing DB', async () => {
  const { handler,calls } = fixture(); assert.equal((await handler(request('wrong'))).status,401); assert.deepEqual(calls,[]);
});
test('dry run ignores body overrides and never starts deletion', async () => {
  const { handler,calls } = fixture({ dry:true }); assert.equal((await handler(request())).status,200);
  assert.deepEqual(calls,[['preview_guest_cleanup']]);
});
test('failed recheck never reaches existing deletion handler', async () => {
  const { handler,calls } = fixture({ claimed:false }); await handler(request());
  assert.deepEqual(calls,[['preview_guest_cleanup'],['claim_guest_cleanup']]);
});
test('reuses existing handler: claim, marker, nested Storage files, then Auth deletion', async () => {
  const { handler,calls } = fixture(); assert.equal((await handler(request())).status,200);
  assert.deepEqual(calls.slice(0,3),[['preview_guest_cleanup'],['claim_guest_cleanup'],['begin_account_deletion']]);
  assert.deepEqual(calls.at(-1),['delete','guest']);
  assert.deepEqual(calls.find(c => c[0]==='remove'),['remove',['guest/nested/photo']]);
});
test('Storage failure preserves user and records retryable failure', async () => {
  const { handler,calls } = fixture({ storageError:true }); assert.equal((await handler(request())).status,500);
  assert.ok(!calls.some(c => c[0]==='delete'));
  assert.deepEqual(calls.at(-1),['log',{last_error:'image_delete_failed'}]);
});
