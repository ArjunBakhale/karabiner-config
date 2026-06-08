import { describe, expect, it } from "vitest";
import {
  documentReceivedSchema,
  findingDispositionCommandSchema,
  findingSchema,
  tokenUploadRequestSchema
} from "../src/index.js";

describe("contracts", () => {
  it("validates document-received jobs", () => {
    const parsed = documentReceivedSchema.parse({
      type: "DocumentReceived",
      tenantId: "00000000-0000-4000-8000-000000000001",
      documentId: "00000000-0000-4000-8000-000000000002",
      documentVersionId: "00000000-0000-4000-8000-000000000003",
      uploadedVia: "token"
    });

    expect(parsed.type).toBe("DocumentReceived");
    expect(parsed.occurredAt).toBeTruthy();
  });

  it("rejects invalid token upload requests", () => {
    expect(() =>
      tokenUploadRequestSchema.parse({
        fileName: "",
        mimeType: "application/pdf",
        byteSize: -1
      })
    ).toThrow();
  });

  it("limits finding disposition commands to explicit user actions", () => {
    expect(() =>
      findingDispositionCommandSchema.parse({
        findingId: "00000000-0000-4000-8000-000000000010",
        disposition: "open"
      })
    ).toThrow();
  });

  it("models findings as discrepancies", () => {
    const finding = findingSchema.parse({
      id: "00000000-0000-4000-8000-000000000011",
      tenant_id: "00000000-0000-4000-8000-000000000001",
      site_id: "00000000-0000-4000-8000-000000000012",
      requirement_instance_id: null,
      severity: "warning",
      code: "PI_NAME_MISMATCH",
      message: "Asserted PI name differs from evidence.",
      asserted_state: { piName: "Dr. A" },
      evidence_summary: { piName: "Dr. B" },
      disposition: "open",
      disposition_changed_by: null,
      disposition_changed_at: null,
      created_at: "2026-01-01T00:00:00.000Z"
    });

    expect(finding.disposition).toBe("open");
  });
});
