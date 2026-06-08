import { describe, expect, it } from "vitest";
import {
  assertTenantPrefixedStoragePath,
  buildTenantStoragePath,
  checksumSha256
} from "../src/index.js";

describe("storage helpers", () => {
  const tenantId = "00000000-0000-4000-8000-000000000001";

  it("builds tenant-prefixed storage paths", () => {
    expect(buildTenantStoragePath(tenantId, "documents", "Site 001", "1572 v1.pdf")).toBe(
      `${tenantId}/documents/Site-001/1572-v1.pdf`
    );
  });

  it("rejects non-tenant-prefixed paths", () => {
    expect(() => assertTenantPrefixedStoragePath(tenantId, "other/documents/file.pdf")).toThrow(
      "tenant-prefixed"
    );
  });

  it("computes sha256 checksums", async () => {
    await expect(checksumSha256("greenlight")).resolves.toHaveLength(64);
  });
});
