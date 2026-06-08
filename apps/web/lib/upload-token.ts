import { checksumSha256 } from "@greenlight/core";

export type ParsedUploadToken = {
  tenantId: string;
  secret: string;
};

export function parseUploadToken(token: string): ParsedUploadToken | null {
  const [tenantId, secret] = token.split(".");

  if (!tenantId || !secret || token.split(".").length !== 2) {
    return null;
  }

  return { tenantId, secret };
}

export async function hashUploadTokenSecret(secret: string): Promise<string> {
  return checksumSha256(secret);
}
