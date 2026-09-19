import { createClient } from "npm:@supabase/supabase-js@2";
import { createCleanupHandler } from "./handler.mjs";

const url = Deno.env.get("SUPABASE_URL")!;
Deno.serve(createCleanupHandler(() => createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
  auth: { persistSession: false, autoRefreshToken: false },
}), url, Deno.env.get("GUEST_CLEANUP_SECRET")));
