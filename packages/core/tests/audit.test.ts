import { describe, expect, it } from "vitest";
import { appendAuditEvent, computeAuditHash, type AuditPgClient } from "../src/index.js";

describe("audit writer", () => {
  it("computes stable long hashes", () => {
    const left = computeAuditHash({
      tenantId: "tenant-1",
      seq: 1,
      prevHash: null,
      actor: "system",
      action: "created",
      entityType: "site",
      payload: { b: 2, a: 1 }
    });
    const right = computeAuditHash({
      tenantId: "tenant-1",
      seq: 1,
      prevHash: null,
      actor: "system",
      action: "created",
      entityType: "site",
      payload: { a: 1, b: 2 }
    });

    expect(left).toBe(right);
    expect(left.length).toBeGreaterThan(20);
  });

  it("retries unique conflicts", async () => {
    let insertAttempts = 0;
    const client: AuditPgClient = {
      async query(text: string) {
        if (text.startsWith("select seq")) {
          return { rows: [] } as never;
        }

        if (text.includes("insert into public.audit_events")) {
          insertAttempts += 1;
          if (insertAttempts === 1) {
            const error = new Error("duplicate") as Error & { code: string };
            error.code = "23505";
            throw error;
          }

          return {
            rows: [
              {
                id: "event-1",
                tenant_id: "tenant-1",
                seq: 1,
                prev_hash: null,
                hash: "a".repeat(64),
                actor: "system",
                action: "created",
                entity_type: "site",
                entity_id: null,
                payload: {},
                created_at: "2026-01-01T00:00:00.000Z"
              }
            ]
          } as never;
        }

        return { rows: [] } as never;
      }
    };

    const inserted = await appendAuditEvent(client, {
      tenantId: "tenant-1",
      actor: "system",
      action: "created",
      entityType: "site"
    });

    expect(insertAttempts).toBe(2);
    expect(inserted.seq).toBe(1);
  });
});
