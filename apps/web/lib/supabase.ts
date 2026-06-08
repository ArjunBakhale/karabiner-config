import { createRlsServerClient, createServiceRoleClient } from "@greenlight/core";
import { cookies } from "next/headers";
import { getPublicSupabaseEnv, getServiceSupabaseEnv } from "./env";

export async function createWebRlsClient() {
  const cookieStore = await cookies();
  const env = getPublicSupabaseEnv();

  return createRlsServerClient({
    supabaseUrl: env.supabaseUrl,
    anonKey: env.anonKey,
    cookies: {
      getAll() {
        return cookieStore.getAll();
      },
      setAll() {
        return undefined;
      }
    }
  });
}

export function createWebServiceClient() {
  const env = getServiceSupabaseEnv();

  return {
    client: createServiceRoleClient({
      supabaseUrl: env.supabaseUrl,
      serviceRoleKey: env.serviceRoleKey
    }),
    storageBucket: env.storageBucket
  };
}
