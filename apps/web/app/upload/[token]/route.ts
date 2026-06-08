import {
  buildTenantStoragePath,
  createServiceRoleClient,
  tokenUploadRequestSchema,
  withTenant
} from "@greenlight/core";
import { NextResponse } from "next/server";
import { getServiceSupabaseEnv } from "@/lib/env";
import { hashUploadTokenSecret, parseUploadToken } from "@/lib/upload-token";

export const dynamic = "force-dynamic";

export async function GET(_request: Request, context: { params: Promise<{ token: string }> }) {
  const { token } = await context.params;

  return new Response(
    `<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Greenlight upload</title></head><body><main><h1>Greenlight document upload</h1><p>POST file metadata to this endpoint to receive a signed upload URL.</p><code>/upload/${token}</code></main></body></html>`,
    {
      headers: {
        "content-type": "text/html; charset=utf-8"
      }
    }
  );
}

export async function POST(request: Request, context: { params: Promise<{ token: string }> }) {
  const { token } = await context.params;
  const parsedToken = parseUploadToken(token);

  if (!parsedToken) {
    return NextResponse.json({ error: "invalid_token" }, { status: 401 });
  }

  const body = tokenUploadRequestSchema.safeParse(await request.json().catch(() => null));
  if (!body.success) {
    return NextResponse.json({ error: "invalid_request" }, { status: 400 });
  }

  const env = getServiceSupabaseEnv();
  const service = createServiceRoleClient({
    supabaseUrl: env.supabaseUrl,
    serviceRoleKey: env.serviceRoleKey
  });
  const scoped = withTenant(parsedToken.tenantId).bind(service);
  const tokenHash = await hashUploadTokenSecret(parsedToken.secret);

  const { data: uploadToken, error } = await scoped
    .from("upload_tokens")
    .select("*")
    .eq("token_hash", tokenHash)
    .gt("expires_at", new Date().toISOString())
    .is("used_at", null)
    .maybeSingle();

  if (error) {
    return NextResponse.json({ error: "token_lookup_failed" }, { status: 500 });
  }

  if (!uploadToken) {
    return NextResponse.json({ error: "invalid_token" }, { status: 401 });
  }

  const uploadTokenId = String(uploadToken.id);
  const storagePath = buildTenantStoragePath(
    parsedToken.tenantId,
    "token-uploads",
    uploadTokenId,
    body.data.fileName
  );
  const { data: signed, error: signedError } = await service.storage
    .from(env.storageBucket)
    .createSignedUploadUrl(storagePath);

  if (signedError) {
    return NextResponse.json({ error: "signed_upload_failed" }, { status: 500 });
  }

  return NextResponse.json({
    uploadUrl: signed.signedUrl,
    storagePath
  });
}
