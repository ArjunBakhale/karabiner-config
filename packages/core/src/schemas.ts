import { z } from "zod";

export const uuidSchema = z.string().uuid();
export const isoDateTimeSchema = z.string().datetime({ offset: true });

export const appRoleSchema = z.enum(["admin", "manager", "cta", "viewer"]);
export const personnelRoleSchema = z.enum(["pi", "sub_i", "coordinator", "pharmacist", "other"]);
export const ownerTypeSchema = z.enum(["organization", "person", "site", "study"]);
export const findingDispositionSchema = z.enum(["open", "accepted", "dismissed"]);

export const userClaimsSchema = z.object({
  sub: uuidSchema,
  tenant_id: uuidSchema,
  user_role: appRoleSchema
});

export const dashboardContextSchema = z.object({
  tenantId: uuidSchema,
  userId: uuidSchema,
  role: appRoleSchema
});

export const tokenUploadRequestSchema = z.object({
  fileName: z.string().min(1).max(240),
  mimeType: z.string().min(1).max(120),
  byteSize: z.number().int().nonnegative()
});

export const tokenUploadResponseSchema = z.object({
  uploadUrl: z.string().url(),
  storagePath: z.string().min(1)
});

export const findingDispositionCommandSchema = z.object({
  findingId: uuidSchema,
  disposition: z.enum(["accepted", "dismissed"])
});

export const blueprintRequestSchema = z.object({
  studyId: uuidSchema
});

export const validationRequestSchema = z.object({
  documentVersionId: uuidSchema
});

export const collectionRequestSchema = z.object({
  siteId: uuidSchema
});

export const commandCenterRequestSchema = z.object({
  siteId: uuidSchema.optional(),
  studyId: uuidSchema.optional()
});

export const irbRequestSchema = z.object({
  siteId: uuidSchema.optional(),
  studyId: uuidSchema
});

export const notImplementedResponseSchema = z.object({
  error: z.literal("not_implemented")
});

export type UserClaims = z.infer<typeof userClaimsSchema>;
export type DashboardContext = z.infer<typeof dashboardContextSchema>;
export type TokenUploadRequest = z.infer<typeof tokenUploadRequestSchema>;
export type TokenUploadResponse = z.infer<typeof tokenUploadResponseSchema>;
export type FindingDispositionCommand = z.infer<typeof findingDispositionCommandSchema>;
