function requiredEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

export function getWorkerEnv() {
  return {
    port: Number(process.env.PORT ?? 4000),
    supabaseUrl: requiredEnv("SUPABASE_URL"),
    serviceRoleKey: requiredEnv("SUPABASE_SERVICE_ROLE_KEY"),
    databaseUrl: requiredEnv("SUPABASE_DB_URL")
  };
}
