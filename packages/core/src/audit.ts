import { createHash } from "node:crypto";
import type { QueryResult } from "pg";
import type { Json } from "./database.js";

export type AuditPgClient = {
  query<T extends Record<string, unknown> = Record<string, unknown>>(
    text: string,
    values?: unknown[]
  ): Promise<QueryResult<T>>;
  release?: () => void;
};

export type AuditPgPool = {
  connect(): Promise<AuditPgClient>;
};

export type AppendAuditEventInput = {
  tenantId: string;
  actor: string;
  action: string;
  entityType: string;
  entityId?: string | null;
  payload?: Json;
};

export type AuditEventRow = {
  id: string;
  tenant_id: string;
  seq: number;
  prev_hash: string | null;
  hash: string;
  actor: string;
  action: string;
  entity_type: string;
  entity_id: string | null;
  payload: Json;
  created_at: string;
};

const RETRYABLE_PG_CODES = new Set(["23505", "40001", "40P01"]);

function stableStringify(value: unknown): string {
  if (value === null || typeof value !== "object") {
    return JSON.stringify(value);
  }

  if (Array.isArray(value)) {
    return `[${value.map((item) => stableStringify(item)).join(",")}]`;
  }

  const object = value as Record<string, unknown>;
  return `{${Object.keys(object)
    .sort()
    .map((key) => `${JSON.stringify(key)}:${stableStringify(object[key])}`)
    .join(",")}}`;
}

export function computeAuditHash(input: {
  tenantId: string;
  seq: number;
  prevHash: string | null;
  actor: string;
  action: string;
  entityType: string;
  entityId?: string | null;
  payload?: Json;
}): string {
  return createHash("sha256")
    .update(
      stableStringify({
        tenantId: input.tenantId,
        seq: input.seq,
        prevHash: input.prevHash,
        actor: input.actor,
        action: input.action,
        entityType: input.entityType,
        entityId: input.entityId ?? null,
        payload: input.payload ?? {}
      })
    )
    .digest("hex");
}

function isPool(connection: AuditPgPool | AuditPgClient): connection is AuditPgPool {
  return "connect" in connection;
}

function isRetryable(error: unknown): boolean {
  return typeof error === "object" && error !== null && RETRYABLE_PG_CODES.has(String((error as { code?: string }).code));
}

export async function appendAuditEvent(
  connection: AuditPgPool | AuditPgClient,
  input: AppendAuditEventInput,
  options: { maxRetries?: number } = {}
): Promise<AuditEventRow> {
  const maxRetries = options.maxRetries ?? 3;
  let attempt = 0;

  while (true) {
    const client = isPool(connection) ? await connection.connect() : connection;

    try {
      await client.query("begin");
      await client.query("select pg_advisory_xact_lock(hashtext($1), hashtext($2))", [
        "greenlight_audit",
        input.tenantId
      ]);

      const latest = await client.query<{ seq: number; hash: string }>(
        "select seq, hash from public.audit_events where tenant_id = $1 order by seq desc limit 1 for update",
        [input.tenantId]
      );
      const previous = latest.rows[0] ?? null;
      const seq = previous ? Number(previous.seq) + 1 : 1;
      const prevHash = previous?.hash ?? null;
      const hash = computeAuditHash({
          tenantId: input.tenantId,
          seq,
          prevHash,
          actor: input.actor,
          action: input.action,
          entityType: input.entityType,
          entityId: input.entityId,
        payload: input.payload
      });

      const inserted = await client.query<AuditEventRow>(
        `insert into public.audit_events
          (tenant_id, seq, prev_hash, hash, actor, action, entity_type, entity_id, payload)
         values ($1, $2, $3, $4, $5, $6, $7, $8, $9::jsonb)
         returning *`,
        [
          input.tenantId,
          seq,
          prevHash,
          hash,
          input.actor,
          input.action,
          input.entityType,
          input.entityId ?? null,
          JSON.stringify(input.payload ?? {})
        ]
      );

      const row = inserted.rows[0];
      if (!row) {
        throw new Error("Audit insert returned no row");
      }

      await client.query("commit");
      return row;
    } catch (error) {
      await client.query("rollback").catch(() => undefined);

      if (isRetryable(error) && attempt < maxRetries) {
        attempt += 1;
        continue;
      }

      throw error;
    } finally {
      if (isPool(connection)) {
        client.release?.();
      }
    }
  }
}
