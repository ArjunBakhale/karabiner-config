function requiredEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

export function getPublicSupabaseEnv() {
  return {
    supabaseUrl: requiredEnv("NEXT_PUBLIC_SUPABASE_URL"),
    anonKey: requiredEnv("NEXT_PUBLIC_SUPABASE_ANON_KEY")
  };
}

export function getServiceSupabaseEnv() {
  return {
    supabaseUrl: process.env.SUPABASE_URL ?? requiredEnv("NEXT_PUBLIC_SUPABASE_URL"),
    serviceRoleKey: requiredEnv("SUPABASE_SERVICE_ROLE_KEY"),
    storageBucket: process.env.SUPABASE_STORAGE_BUCKET ?? "trial-documents"
  };
}
