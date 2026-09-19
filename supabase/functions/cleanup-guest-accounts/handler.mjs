const deleteHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};
const deleteReply = (status, body) =>
  new Response(JSON.stringify(body), { status, headers: deleteHeaders });

const createDeleteHandler = (createAdmin, url) => async (request) => {
  if (request.method === "OPTIONS") return new Response(null, { headers: deleteHeaders });
  if (request.method !== "POST") return deleteReply(405, { error: "method_not_allowed" });
  const token = request.headers.get("Authorization")?.match(/^Bearer (.+)$/i)?.[1];
  if (!token) return deleteReply(401, { error: "authentication_required" });
  const admin = createAdmin();
  try {
    const { data, error } = await admin.auth.getClaims(token);
    const claims = data?.claims;
    if (error || !claims?.sub || claims.role !== "authenticated" ||
        claims.iss !== `${url}/auth/v1`) {
      return deleteReply(401, { error: "invalid_session" });
    }
    let uid = claims.sub;
    const body = await request.json();
    const existing = await admin.auth.admin.getUserById(uid);
    if (existing.error?.status === 404 || existing.error?.code === "user_not_found") {
      if (body.action != null) return deleteReply(401, { error: 'target_session_missing' });
      return deleteReply(200, { deleted: true });
    }
    if (existing.error || !existing.data.user) throw new Error("user_lookup_failed");
    const verified = await admin.auth.getUser(token);
    if (verified.error || verified.data.user?.id !== uid) return deleteReply(401, { error: "invalid_session" });
    if (body.action === 'prepare_guest') {
      if (verified.data.user.is_anonymous !== true) return deleteReply(403, { error: 'guest_required' });
      const prepared = await admin.rpc('prepare_guest_transfer', {
        p_source: uid, p_revisions: body.revisions,
      });
      if (prepared.error) return deleteReply(409, { error: 'guest_changed_or_setup_missing' });
      return deleteReply(200, { ticket: prepared.data });
    }
    if (body.confirm !== "DELETE") return deleteReply(400, { error: "confirmation_required" });
    if (body.action === 'finish_guest') {
      if (verified.data.user.is_anonymous !== false ||
          !verified.data.user.identities?.some((identity) => identity.provider === 'google')) {
        return deleteReply(403, { error: 'google_login_required' });
      }
      if (typeof body.ticket !== 'string') return deleteReply(400, { error: 'ticket_required' });
      const claimed = await admin.rpc('claim_guest_transfer', { p_ticket: body.ticket, p_target: uid });
      if (claimed.error) return deleteReply(409, { error: 'guest_transfer_requires_review' });
      uid = claimed.data;
      const source = await admin.auth.admin.getUserById(uid);
      if (source.error?.status === 404 || source.error?.code === 'user_not_found') {
        return deleteReply(200, { deleted: true });
      }
      if (source.error || source.data.user?.is_anonymous !== true) {
        return deleteReply(409, { error: 'source_no_longer_guest' });
      }
    } else if (body.action != null) {
      return deleteReply(400, { error: 'unknown_action' });
    }
    const locked = await admin.rpc("begin_account_deletion", { p_user_id: uid });
    if (locked.error) throw new Error("deletion_setup_failed");

    for (let batch = 0; batch < 50; batch++) {
      const files = await admin.rpc("account_deletion_images", { p_user_id: uid });
      if (files.error) throw new Error("image_list_failed");
      if (!files.data.length) {
        const removed = await admin.auth.admin.deleteUser(uid);
        if (removed.error) throw new Error("user_delete_failed");
        return deleteReply(200, { deleted: true });
      }
      const removed = await admin.storage.from("bike-images").remove(files.data.map((file) => file.name));
      if (removed.error) throw new Error("image_delete_failed");
    }
    return deleteReply(202, { deleted: false, retry: true });
  } catch (error) {
    const code = error instanceof Error && /^[a-z_]+$/.test(error.message)
      ? error.message : "deletion_failed";
    return deleteReply(500, { error: code });
  }
};

const reply = (status, body) => new Response(JSON.stringify(body), {
  status, headers: { 'Content-Type': 'application/json' },
});
const checked = (result) => {
  if (result.error) throw new Error('cleanup_database_failed');
  return result.data;
};

async function deleteClaimedGuest(admin, url, uid) {
  const internalAdmin = {
    rpc: (...args) => admin.rpc(...args),
    storage: admin.storage,
    auth: {
      admin: admin.auth.admin,
      getClaims: async () => ({ data: { claims: { sub: uid, role: 'authenticated', iss: `${url}/auth/v1` } } }),
      getUser: async () => admin.auth.admin.getUserById(uid),
    },
  };
  return createDeleteHandler(() => internalAdmin, url)(new Request(url, {
    method: 'POST', headers: { Authorization: 'Bearer internal-cleanup' },
    body: JSON.stringify({ confirm: 'DELETE' }),
  }));
}

export const createCleanupHandler = (createAdmin, url, secret) => async (request) => {
  if (request.method !== 'POST') return reply(405, { error: 'method_not_allowed' });
  if (!secret || secret.length < 32 || request.headers.get('x-cleanup-secret') !== secret) {
    return reply(401, { error: 'unauthorized' });
  }
  try {
    const admin = createAdmin();
    const settings = checked(await admin.from('guest_cleanup_settings').select('*').single());
    if (!settings.enabled) return reply(200, { enabled: false });
    const candidates = checked(await admin.rpc('preview_guest_cleanup')
      .order('eligible_at').order('user_id').limit(settings.batch_size));
    if (settings.dry_run) {
      console.log(JSON.stringify({ event: 'guest_cleanup_dry_run', candidates }));
      return reply(200, { dry_run: true, candidates });
    }
    const pending = checked(await admin.from('guest_cleanup_log').select('user_id')
      .is('deleted_at', null).order('attempted_at').limit(settings.batch_size));
    const ids = [...new Set([...pending, ...candidates].map((row) => row.user_id))].slice(0, settings.batch_size);
    const results = [];
    const started = Date.now();
    for (const uid of ids) {
      if (Date.now() - started > 120000) break;
      if (!checked(await admin.rpc('claim_guest_cleanup', { p_user_id: uid }))) continue;
      const response = await deleteClaimedGuest(admin, url, uid);
      const result = await response.json();
      if (!result.deleted) {
        checked(await admin.from('guest_cleanup_log').update({ last_error: result.error ?? 'retry_required' })
          .eq('user_id', uid).is('deleted_at', null));
      }
      results.push({ user_id: uid, ...result });
    }
    console.log(JSON.stringify({ event: 'guest_cleanup', results }));
    return reply(results.some((r) => r.error) ? 500 : 200, { results });
  } catch {
    console.error('guest_cleanup_failed');
    return reply(500, { error: 'guest_cleanup_failed' });
  }
};