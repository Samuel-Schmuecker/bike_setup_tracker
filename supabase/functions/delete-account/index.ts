import { createClient } from "npm:@supabase/supabase-js@2";
import { createDeleteHandler } from "./handler.mjs";
const url = Deno.env.get("SUPABASE_URL")!;
Deno.serve(createDeleteHandler(() => createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
  auth: { persistSession: false, autoRefreshToken: false },
}), url));
