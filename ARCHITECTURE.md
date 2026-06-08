# Greenlight Architecture

Greenlight is a PHI-free sponsor/CRO-facing SaaS for clinical-trial site activation. It compresses the path from "site selected" to "ready to enroll" by managing asserted operational state, immutable document evidence, discrepancy findings, and audit history.

## Stack

- `apps/web`: Next.js App Router for Vercel. Holds the dashboard shell, authenticated API route handlers, and unauthenticated tokenized uploads.
- `apps/worker`: Express service for Render. Runs `pg-boss` against the Supabase Postgres connection and registers background consumers.
- `packages/core`: frozen shared contracts, generated database types, DTO schemas, clients, tenant scoping, storage helpers, Anthropic wrapper, and audit writer.
- `packages/config`: shared TypeScript, ESLint, and Prettier config.
- `supabase`: the single migration, seed data, config, and generated TypeScript database types.

No Docker, AWS, NestJS, OCR, or patient-data ingestion is part of this foundation.

## Frozen Contracts

The following are frozen after this groundwork:

- `supabase/migrations/0001_init.sql`
- Everything in `packages/core`

Later agents must read these contracts and must not modify them. If a feature appears to require a schema or shared-contract change, stop and surface the needed change in review output.

## Parallel Ownership

Parallel streams should edit disjoint directories:

- Blueprint work: `apps/web/app/api/blueprint` and feature-local UI under `apps/web`
- Validation work: `apps/web/app/api/validation` and `apps/worker/src/jobs/validation.ts`
- Collection work: `apps/web/app/api/collection`
- Command center work: `apps/web/app/api/command-center`
- IRB work: `apps/web/app/api/irb`

Avoid broad refactors and root-level churn while streams are active.

## Domain Model

Structured entities such as people, sites, and requirement instances are asserted state. `document_versions` are immutable evidence. `findings` are discrepancies between asserted state and evidence.

Findings are flag-never-fix: the worker may create findings and evidence, but it must never auto-resolve, silently edit, or delete findings. Only explicit user action changes a finding disposition, and that action must write an audit event.

## Service-Role Discipline

Supabase service-role clients bypass RLS. Every worker or token-path query must go through `withTenant(tenantId)` from `@greenlight/core`, which filters reads by `tenant_id` and stamps writes with the same `tenant_id`.

The unauthenticated upload route expects tenant-bearing tokens in the form:

```text
<tenant_uuid>.<secret>
```

The route hashes the secret, scopes the lookup with `withTenant(tenant_uuid)`, validates `upload_tokens`, then requests a signed upload URL for a tenant-prefixed storage path.

## Schema-Enforced Contracts

- Cross-table references are same-tenant composite references wherever the model permits.
- `tenant_id` is immutable after insert.
- Authenticated RLS fail-closes when the JWT lacks `tenant_id`.
- The Supabase custom access-token hook must be enabled at `pg-functions://postgres/public/custom_access_token_hook`.
- `document_versions` are immutable.
- Insert exactly one version per document per statement.
- A document version must be `documents.current_version + 1`.
- The trigger updates `documents.current_version`; application code must not set it directly.
- `document_versions.checksum` is required and must be longer than 20 characters.
- `document_versions.storage_path` must start with `<tenant_uuid>/`.
- `uploaded_via='user'` requires `uploaded_by`; token and worker uploads require `uploaded_by` to be null.
- `requirement_fulfillments` allow at most one `accepted` row per requirement instance.
- `proposed` fulfillments have no decision user/time; `accepted` and `rejected` require both.
- Site-scoped requirement instances require `person_id` null.
- Person-scoped requirement instances require a prior `site_personnel` assignment, including matching role when `applies_to_role` is set.
- Satisfied requirement instances require `satisfied_at`.
- Findings must reference a site and/or requirement instance.
- Open findings have no disposition user/time; accepted or dismissed findings require both.
- `upload_tokens` are closed to authenticated clients and store only `token_hash`.
- `audit_events` are append-only and must be written only through the core audit writer.

## Audit Writer

`appendAuditEvent` in `@greenlight/core` writes audit rows in a Postgres transaction. It takes a per-tenant advisory lock, reads the latest `(seq, hash)`, computes the next sequence and hash, inserts one row, and retries serialization, deadlock, and unique-conflict failures.

Every state change must write an audit event through this writer.

## Local Supabase

Install the Supabase CLI, then run:

```bash
supabase start
supabase db reset
supabase gen types typescript --local > supabase/types/database.types.ts
```

The integration test for the access-token hook signs in `admin@greenlight.local` with password `greenlight-demo-password` and asserts RLS returns the seeded `GL-101` study. It runs when `SUPABASE_URL` and `SUPABASE_ANON_KEY` are present.

## Local Development

Install dependencies and run the build graph:

```bash
pnpm install
pnpm typecheck
pnpm test
pnpm build
```

Run the web and worker services:

```bash
pnpm --filter @greenlight/web dev
pnpm --filter @greenlight/worker dev
```
