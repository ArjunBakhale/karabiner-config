import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "./database.js";

type TenantRecord = Record<string, unknown> & { tenant_id?: string };
type QueryResult<T = unknown> = Promise<{ data: T | null; error: { message: string } | null }>;
type TenantQueryBuilder<T = Record<string, unknown>> = {
  eq(column: string, value: unknown): TenantQueryBuilder<T>;
  gt(column: string, value: unknown): TenantQueryBuilder<T>;
  is(column: string, value: unknown): TenantQueryBuilder<T>;
  maybeSingle(): QueryResult<T>;
};
type UntypedSupabaseClient = {
  from(table: string): {
    select(columns?: string): TenantQueryBuilder;
    insert(values: unknown): unknown;
    update(values: unknown): { eq(column: string, value: string): unknown };
    upsert(values: unknown): unknown;
    delete(): { eq(column: string, value: string): unknown };
  };
};

function addTenant<T extends TenantRecord>(tenantId: string, value: T): T & { tenant_id: string } {
  return {
    ...value,
    tenant_id: tenantId
  };
}

function addTenantToMany<T extends TenantRecord>(
  tenantId: string,
  values: T | T[]
): (T & { tenant_id: string }) | Array<T & { tenant_id: string }> {
  return Array.isArray(values)
    ? values.map((value) => addTenant(tenantId, value))
    : addTenant(tenantId, values);
}

export function withTenant(tenantId: string) {
  if (!tenantId) {
    throw new Error("tenantId is required for service-role queries");
  }

  return {
    bind(client: SupabaseClient<Database>) {
      const untypedClient = client as unknown as UntypedSupabaseClient;

      return {
        from(table: keyof Database["public"]["Tables"] & string) {
          return {
            select(columns = "*") {
              return untypedClient.from(table).select(columns).eq("tenant_id", tenantId);
            },
            insert(values: TenantRecord | TenantRecord[]) {
              return untypedClient.from(table).insert(addTenantToMany(tenantId, values));
            },
            update(values: TenantRecord) {
              return untypedClient.from(table).update(addTenant(tenantId, values)).eq("tenant_id", tenantId);
            },
            upsert(values: TenantRecord | TenantRecord[]) {
              return untypedClient.from(table).upsert(addTenantToMany(tenantId, values));
            },
            delete() {
              return untypedClient.from(table).delete().eq("tenant_id", tenantId);
            }
          };
        }
      };
    }
  };
}
