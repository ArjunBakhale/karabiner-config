import { createClient } from "@supabase/supabase-js";
import { describe, expect, it } from "vitest";
import type { Database } from "../src/index.js";

const url = process.env.SUPABASE_URL ?? process.env.NEXT_PUBLIC_SUPABASE_URL;
const anonKey = process.env.SUPABASE_ANON_KEY ?? process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

const run = url && anonKey ? describe : describe.skip;

run("custom access token hook", () => {
  it("signs in a seeded user and returns tenant rows through RLS", async () => {
    const client = createClient<Database>(url!, anonKey!);

    const auth = await client.auth.signInWithPassword({
      email: "admin@greenlight.local",
      password: "greenlight-demo-password"
    });

    expect(auth.error).toBeNull();

    const { data, error } = await client.from("studies").select("tenant_id, protocol_number");

    expect(error).toBeNull();
    expect(data).toEqual(
      expect.arrayContaining([
        {
          tenant_id: "00000000-0000-4000-8000-000000000001",
          protocol_number: "GL-101"
        }
      ])
    );
  });
});
