import { z } from "zod";
import { uuidSchema } from "./schemas.js";

export const findingSchema = z.object({
  id: uuidSchema,
  tenant_id: uuidSchema,
  site_id: uuidSchema.nullable(),
  requirement_instance_id: uuidSchema.nullable(),
  severity: z.enum(["info", "warning", "critical"]),
  code: z.string().min(1),
  message: z.string().min(1),
  asserted_state: z.record(z.unknown()),
  evidence_summary: z.record(z.unknown()),
  disposition: z.enum(["open", "accepted", "dismissed"]),
  disposition_changed_by: uuidSchema.nullable(),
  disposition_changed_at: z.string().datetime({ offset: true }).nullable(),
  created_at: z.string().datetime({ offset: true })
});

export type Finding = z.infer<typeof findingSchema>;
