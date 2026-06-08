import { createServerClient } from "@supabase/ssr";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "./database.js";

export type GreenlightSupabaseClient = SupabaseClient<Database>;

export type CookieMethods = {
  getAll?: () => Array<{ name: string; value: string }>;
  setAll?: (cookies: Array<{ name: string; value: string; options?: Record<string, unknown> }>) => void;
  get?: (name: string) => string | undefined;
  set?: (name: string, value: string, options?: Record<string, unknown>) => void;
  remove?: (name: string, options?: Record<string, unknown>) => void;
};

export function createRlsServerClient(args: {
  supabaseUrl: string;
  anonKey: string;
  cookies: CookieMethods;
}): GreenlightSupabaseClient {
  return createServerClient<Database>(args.supabaseUrl, args.anonKey, {
    cookies: args.cookies
  }) as unknown as GreenlightSupabaseClient;
}

export function createServiceRoleClient(args: {
  supabaseUrl: string;
  serviceRoleKey: string;
}): GreenlightSupabaseClient {
  return createClient<Database>(args.supabaseUrl, args.serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  });
}
