import { z } from "zod";
import { uuidSchema } from "./schemas.js";

const baseContract = z.object({
  tenantId: uuidSchema,
  occurredAt: z.string().datetime({ offset: true }).default(() => new Date().toISOString())
});

export const documentReceivedSchema = baseContract.extend({
  type: z.literal("DocumentReceived"),
  documentId: uuidSchema,
  documentVersionId: uuidSchema,
  uploadedVia: z.enum(["user", "token", "worker"])
});

export const documentValidatedSchema = baseContract.extend({
  type: z.literal("DocumentValidated"),
  documentVersionId: uuidSchema,
  findingIds: z.array(uuidSchema)
});

export const requirementSatisfiedSchema = baseContract.extend({
  type: z.literal("RequirementSatisfied"),
  requirementInstanceId: uuidSchema,
  documentVersionId: uuidSchema
});

export const siteStalledSchema = baseContract.extend({
  type: z.literal("SiteStalled"),
  siteId: uuidSchema,
  reason: z.string().min(1)
});

export const irbPackageAssembledSchema = baseContract.extend({
  type: z.literal("IrbPackageAssembled"),
  irbSubmissionId: uuidSchema,
  siteId: uuidSchema.optional(),
  studyId: uuidSchema
});

export const greenlightJobSchema = z.discriminatedUnion("type", [
  documentReceivedSchema,
  documentValidatedSchema,
  requirementSatisfiedSchema,
  siteStalledSchema,
  irbPackageAssembledSchema
]);

export type DocumentReceived = z.infer<typeof documentReceivedSchema>;
export type DocumentValidated = z.infer<typeof documentValidatedSchema>;
export type RequirementSatisfied = z.infer<typeof requirementSatisfiedSchema>;
export type SiteStalled = z.infer<typeof siteStalledSchema>;
export type IrbPackageAssembled = z.infer<typeof irbPackageAssembledSchema>;
export type GreenlightJob = z.infer<typeof greenlightJobSchema>;
