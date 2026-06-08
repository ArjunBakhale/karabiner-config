import { createHash } from "node:crypto";

export function buildTenantStoragePath(tenantId: string, ...segments: string[]): string {
  const cleanedSegments = segments
    .flatMap((segment) => segment.split("/"))
    .map((segment) => segment.trim())
    .filter(Boolean)
    .map((segment) => segment.replace(/[^A-Za-z0-9._-]/g, "-"));

  if (cleanedSegments.length === 0) {
    throw new Error("storage path requires at least one segment");
  }

  return [tenantId, ...cleanedSegments].join("/");
}

export function assertTenantPrefixedStoragePath(tenantId: string, storagePath: string): void {
  if (!storagePath.startsWith(`${tenantId}/`)) {
    throw new Error("storage_path must be tenant-prefixed");
  }
}

export async function checksumSha256(input: ArrayBuffer | Uint8Array | Buffer | string): Promise<string> {
  const value = input instanceof ArrayBuffer ? Buffer.from(input) : input;
  return createHash("sha256").update(value).digest("hex");
}
