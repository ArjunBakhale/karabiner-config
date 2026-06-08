import { z } from "zod";
import { uuidSchema } from "./schemas.js";

export const findingSchema = z.object({
  id: uuidSchema,
  tenant_id: uuidSchema,
  site_id: uuidSchema.nullable(),
  requirement_instance_id: uuidSchema.nullable(),
  type: z.string().min(1),
  severity: z.enum(["info", "warning", "blocker"]),
  confidence: z.number().min(0).max(1),
  detail: z.string().nullable(),
  source: z.enum(["system", "user"]),
  disposition: z.enum(["open", "accepted", "dismissed"]),
  disposition_changed_by: uuidSchema.nullable(),
  disposition_changed_at: z.string().datetime({ offset: true }).nullable(),
  created_at: z.string().datetime({ offset: true }),
  updated_at: z.string().datetime({ offset: true })
});

export type Finding = z.infer<typeof findingSchema>;
