import { createServiceRoleClient, greenlightJobSchema, withTenant } from "@greenlight/core";
import type PgBoss from "pg-boss";
import { getWorkerEnv } from "../env.js";

export const VALIDATION_QUEUE = "validation";

export async function registerValidationWorker(boss: PgBoss): Promise<void> {
  await boss.work(VALIDATION_QUEUE, async (jobs) => {
    const batch = Array.isArray(jobs) ? jobs : [jobs];

    for (const job of batch) {
      const parsed = greenlightJobSchema.safeParse(job.data);

      if (!parsed.success) {
        throw new Error("Invalid validation job payload");
      }

      const env = getWorkerEnv();
      const service = createServiceRoleClient({
        supabaseUrl: env.supabaseUrl,
        serviceRoleKey: env.serviceRoleKey
      });

      withTenant(parsed.data.tenantId).bind(service);
    }
  });
}
