

const headers = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};
const reply = (status, body) =>
  new Response(JSON.stringify(body), { status, headers });

export const createDeleteHandler = (createAdmin, url) => async (request) => {
  if (request.method === "OPTIONS") return new Response(null, { headers });
  if (request.method !== "POST") return reply(405, { error: "method_not_allowed" });
  const token = request.headers.get("Authorization")?.match(/^Bearer (.+)$/i)?.[1];
  if (!token) return reply(401, { error: "authentication_required" });
  const admin = createAdmin();
  try {
    // Never accept a target user ID supplied by the caller.
    const { data, error } = await admin.auth.getClaims(token);
    const claims = data?.claims;
    if (error || !claims?.sub || claims.role !== "authenticated" ||
        claims.iss !== `${url}/auth/v1`) {
      return reply(401, { error: "invalid_session" });
    }
    const uid = claims.sub;
    const existing = await admin.auth.admin.getUserById(uid);
    // A repeated request after a lost success response is harmless.
    if (existing.error?.status === 404 || existing.error?.code === "user_not_found") {
      return reply(200, { deleted: true });
    }
    if (existing.error || !existing.data.user) throw new Error("user_lookup_failed");
    const verified = await admin.auth.getUser(token);
    if (verified.error || verified.data.user?.id !== uid) return reply(401, { error: "invalid_session" });
    const body = await request.json();
    if (body.confirm !== "DELETE") return reply(400, { error: "confirmation_required" });
    const locked = await admin.rpc("begin_account_deletion", { p_user_id: uid });
    if (locked.error) throw new Error("deletion_setup_failed");

    // Delete object contents through Storage API, never just their SQL metadata.
    // Read names via SQL so nested paths are included as well.
    for (let batch = 0; batch < 50; batch++) {
      const files = await admin.rpc("account_deletion_images", { p_user_id: uid });
      if (files.error) throw new Error("image_list_failed");
      if (!files.data.length) {
        const removed = await admin.auth.admin.deleteUser(uid);
        if (removed.error) throw new Error("user_delete_failed");
        // FK cascades remove documents, history and the deletion marker.
        return reply(200, { deleted: true });
      }
      const removed = await admin.storage.from("bike-images").remove(files.data.map((file) => file.name));
      if (removed.error) throw new Error("image_delete_failed");
    }
    return reply(202, { deleted: false, retry: true });
  } catch (error) {
    const code = error instanceof Error && /^[a-z_]+$/.test(error.message)
      ? error.message : "deletion_failed";
    return reply(500, { error: code });
  }
};
