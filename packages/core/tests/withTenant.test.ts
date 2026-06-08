import { describe, expect, it } from "vitest";
import { withTenant } from "../src/index.js";

function fakeBuilder(calls: string[]) {
  return {
    select(columns: string) {
      calls.push(`select:${columns}`);
      return this;
    },
    insert(values: unknown) {
      calls.push(`insert:${JSON.stringify(values)}`);
      return this;
    },
    update(values: unknown) {
      calls.push(`update:${JSON.stringify(values)}`);
      return this;
    },
    upsert(values: unknown) {
      calls.push(`upsert:${JSON.stringify(values)}`);
      return this;
    },
    delete() {
      calls.push("delete");
      return this;
    },
    eq(column: string, value: string) {
      calls.push(`eq:${column}:${value}`);
      return this;
    }
  };
}

describe("withTenant", () => {
  it("adds tenant filters to reads", () => {
    const calls: string[] = [];
    const client = {
      from(table: string) {
        calls.push(`from:${table}`);
        return fakeBuilder(calls);
      }
    };

    withTenant("tenant-1").bind(client as never).from("sites").select("id");

    expect(calls).toEqual(["from:sites", "select:id", "eq:tenant_id:tenant-1"]);
  });

  it("sets tenant_id on writes", () => {
    const calls: string[] = [];
    const client = {
      from(table: string) {
        calls.push(`from:${table}`);
        return fakeBuilder(calls);
      }
    };

    withTenant("tenant-1").bind(client as never).from("documents").insert({ title: "1572" });

    expect(calls).toEqual([
      "from:documents",
      'insert:{"title":"1572","tenant_id":"tenant-1"}'
    ]);
  });
});
