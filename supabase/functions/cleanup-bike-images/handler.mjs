const headers = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};
const reply = (status, body) => new Response(JSON.stringify(body), { status, headers });

export const createCleanupHandler = (createAdmin, url) => async (request) => {
  if (request.method === "OPTIONS") return new Response(null, { headers });
  if (request.method !== "POST") return reply(405, { error: "method_not_allowed" });
  const token = request.headers.get("Authorization")?.match(/^Bearer (.+)$/i)?.[1];
  if (!token) return reply(401, { error: "authentication_required" });
  try {
    const admin = createAdmin();
    const { data, error } = await admin.auth.getClaims(token);
    const claims = data?.claims;
    if (error || !claims?.sub || claims.role !== "authenticated" || claims.iss !== `${url}/auth/v1`) {
      return reply(401, { error: "invalid_session" });
    }
    const uid = claims.sub;
    const verified = await admin.auth.getUser(token);
    if (verified.error || verified.data.user?.id !== uid) return reply(401, { error: "invalid_session" });
    // All candidates and references are checked server-side. Caller-supplied
    // file names and account IDs are deliberately not accepted.
    for (let batch = 0; batch < 5; batch++) {
      const files = await admin.rpc("claim_bike_image_cleanup", { p_user_id: uid });
      if (files.error) throw new Error("image_cleanup_claim_failed");
      if (!Array.isArray(files.data)) throw new Error("image_cleanup_claim_failed");
      if (!files.data.length) return reply(200, { complete: true });
      const names = files.data.map((file) => file.name);
      if (names.some((name) => typeof name !== "string" || !name.startsWith(`${uid}/`))) {
        throw new Error("invalid_image_owner");
      }
      // Storage API removes the actual bytes; SQL alone would leave data behind.
      const removed = await admin.storage.from("bike-images").remove(names);
      if (removed.error) throw new Error("image_delete_failed");
      const finished = await admin.rpc("finish_bike_image_cleanup", { p_user_id: uid, p_names: names });
      if (finished.error) throw new Error("image_cleanup_finish_failed");
    }
    return reply(202, { complete: false });
  } catch (error) {
    return reply(500, { error: error instanceof Error && /^[a-z_]+$/.test(error.message)
      ? error.message : "image_cleanup_failed" });
  }
};
