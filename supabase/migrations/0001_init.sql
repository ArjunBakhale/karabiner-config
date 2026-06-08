create extension if not exists pgcrypto;
create extension if not exists vector;

create type public.app_role as enum ('admin', 'manager', 'cta', 'viewer');
create type public.site_status as enum ('selected', 'collecting', 'reviewing', 'ready_to_enroll', 'stalled');
create type public.personnel_role as enum ('pi', 'sub_i', 'coordinator', 'pharmacist', 'other');
create type public.requirement_scope as enum ('site', 'person');
create type public.requirement_status as enum ('missing', 'pending_review', 'satisfied', 'waived');
create type public.document_owner_type as enum ('organization', 'person', 'site', 'study');
create type public.uploaded_via as enum ('user', 'token', 'worker');
create type public.fulfillment_status as enum ('proposed', 'accepted', 'rejected');
create type public.finding_severity as enum ('info', 'warning', 'critical');
create type public.finding_disposition as enum ('open', 'accepted', 'dismissed');
create type public.irb_submission_status as enum ('draft', 'assembled', 'submitted', 'approved', 'rejected');

create table public.tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  created_at timestamptz not null default now()
);

create table public.users (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  auth_user_id uuid not null unique,
  email text not null,
  full_name text not null,
  role public.app_role not null default 'viewer',
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (tenant_id, id),
  unique (tenant_id, auth_user_id)
);

create table public.studies (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  protocol_number text not null,
  title text not null,
  phase text,
  status text not null default 'startup',
  created_at timestamptz not null default now(),
  unique (tenant_id, id),
  unique (tenant_id, protocol_number)
);

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  name text not null,
  kind text not null default 'site',
  country text not null default 'US',
  created_at timestamptz not null default now(),
  unique (tenant_id, id)
);

create table public.sites (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  study_id uuid not null,
  organization_id uuid not null,
  site_number text not null,
  status public.site_status not null default 'selected',
  selected_at timestamptz,
  ready_to_enroll_at timestamptz,
  created_at timestamptz not null default now(),
  unique (tenant_id, id),
  unique (tenant_id, study_id, site_number),
  foreign key (tenant_id, study_id) references public.studies(tenant_id, id) on delete cascade,
  foreign key (tenant_id, organization_id) references public.organizations(tenant_id, id) on delete restrict
);

create table public.people (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  organization_id uuid not null,
  full_name text not null,
  email text,
  npi text,
  created_at timestamptz not null default now(),
  unique (tenant_id, id),
  foreign key (tenant_id, organization_id) references public.organizations(tenant_id, id) on delete cascade
);

create table public.site_personnel (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  site_id uuid not null,
  person_id uuid not null,
  role public.personnel_role not null,
  delegated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (tenant_id, id),
  unique (tenant_id, site_id, person_id, role),
  foreign key (tenant_id, site_id) references public.sites(tenant_id, id) on delete cascade,
  foreign key (tenant_id, person_id) references public.people(tenant_id, id) on delete cascade
);

create table public.requirement_templates (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references public.tenants(id) on delete cascade,
  code text not null,
  name text not null,
  description text,
  scope public.requirement_scope not null,
  applies_to_role public.personnel_role,
  required boolean not null default true,
  created_at timestamptz not null default now(),
  unique (tenant_id, id),
  unique (tenant_id, code),
  check ((scope = 'site' and applies_to_role is null) or scope = 'person')
);

create table public.requirement_instances (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  site_id uuid not null,
  template_id uuid not null references public.requirement_templates(id) on delete restrict,
  person_id uuid,
  status public.requirement_status not null default 'missing',
  satisfied_at timestamptz,
  created_at timestamptz not null default now(),
  unique (tenant_id, id),
  unique (tenant_id, site_id, template_id, person_id),
  foreign key (tenant_id, site_id) references public.sites(tenant_id, id) on delete cascade,
  foreign key (tenant_id, person_id) references public.people(tenant_id, id) on delete cascade,
  check (status <> 'satisfied' or satisfied_at is not null)
);

create table public.documents (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  owner_type public.document_owner_type not null,
  owner_id uuid not null,
  title text not null,
  document_type text not null,
  current_version integer not null default 0,
  created_at timestamptz not null default now(),
  unique (tenant_id, id),
  check (current_version >= 0)
);

create table public.document_versions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  document_id uuid not null,
  version integer not null,
  storage_path text not null,
  checksum text not null,
  mime_type text not null,
  byte_size bigint not null,
  uploaded_via public.uploaded_via not null,
  uploaded_by uuid,
  received_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb,
  unique (tenant_id, id),
  unique (tenant_id, document_id, version),
  foreign key (tenant_id, document_id) references public.documents(tenant_id, id) on delete cascade,
  foreign key (tenant_id, uploaded_by) references public.users(tenant_id, id) on delete restrict,
  check (version > 0),
  check (length(checksum) > 20),
  check (storage_path like tenant_id::text || '/%'),
  check (byte_size >= 0),
  check (
    (uploaded_via = 'user' and uploaded_by is not null) or
    (uploaded_via in ('token', 'worker') and uploaded_by is null)
  )
);

create table public.requirement_fulfillments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  requirement_instance_id uuid not null,
  document_version_id uuid not null,
  status public.fulfillment_status not null default 'proposed',
  decided_by uuid,
  decided_at timestamptz,
  created_at timestamptz not null default now(),
  unique (tenant_id, id),
  foreign key (tenant_id, requirement_instance_id) references public.requirement_instances(tenant_id, id) on delete cascade,
  foreign key (tenant_id, document_version_id) references public.document_versions(tenant_id, id) on delete cascade,
  foreign key (tenant_id, decided_by) references public.users(tenant_id, id) on delete restrict,
  check (
    (status = 'proposed' and decided_by is null and decided_at is null) or
    (status in ('accepted', 'rejected') and decided_by is not null and decided_at is not null)
  )
);

create unique index requirement_fulfillments_one_accepted_idx
  on public.requirement_fulfillments(tenant_id, requirement_instance_id)
  where status = 'accepted';

create table public.findings (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  site_id uuid,
  requirement_instance_id uuid,
  severity public.finding_severity not null default 'warning',
  code text not null,
  message text not null,
  asserted_state jsonb not null default '{}'::jsonb,
  evidence_summary jsonb not null default '{}'::jsonb,
  disposition public.finding_disposition not null default 'open',
  disposition_changed_by uuid,
  disposition_changed_at timestamptz,
  created_at timestamptz not null default now(),
  unique (tenant_id, id),
  foreign key (tenant_id, site_id) references public.sites(tenant_id, id) on delete cascade,
  foreign key (tenant_id, requirement_instance_id) references public.requirement_instances(tenant_id, id) on delete cascade,
  foreign key (tenant_id, disposition_changed_by) references public.users(tenant_id, id) on delete restrict,
  check (site_id is not null or requirement_instance_id is not null),
  check (
    (disposition = 'open' and disposition_changed_by is null and disposition_changed_at is null) or
    (disposition in ('accepted', 'dismissed') and disposition_changed_by is not null and disposition_changed_at is not null)
  )
);

create table public.finding_evidence (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  finding_id uuid not null,
  document_version_id uuid,
  page_number integer,
  excerpt text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (tenant_id, id),
  foreign key (tenant_id, finding_id) references public.findings(tenant_id, id) on delete cascade,
  foreign key (tenant_id, document_version_id) references public.document_versions(tenant_id, id) on delete cascade
);

create table public.irbs (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  kind text not null default 'central',
  website text,
  created_at timestamptz not null default now()
);

create table public.irb_submissions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  study_id uuid not null,
  site_id uuid,
  irb_id uuid not null references public.irbs(id) on delete restrict,
  status public.irb_submission_status not null default 'draft',
  assembled_at timestamptz,
  submitted_at timestamptz,
  created_at timestamptz not null default now(),
  unique (tenant_id, id),
  foreign key (tenant_id, study_id) references public.studies(tenant_id, id) on delete cascade,
  foreign key (tenant_id, site_id) references public.sites(tenant_id, id) on delete cascade
);

create table public.upload_tokens (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  token_hash text not null unique,
  document_id uuid,
  owner_type public.document_owner_type not null,
  owner_id uuid not null,
  purpose text not null,
  expires_at timestamptz not null,
  used_at timestamptz,
  created_by uuid,
  created_at timestamptz not null default now(),
  unique (tenant_id, id),
  foreign key (tenant_id, document_id) references public.documents(tenant_id, id) on delete set null,
  foreign key (tenant_id, created_by) references public.users(tenant_id, id) on delete restrict,
  check (length(token_hash) > 20)
);

create table public.audit_events (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  seq bigint not null,
  prev_hash text,
  hash text not null,
  actor_user_id uuid,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (tenant_id, id),
  unique (tenant_id, seq),
  foreign key (tenant_id, actor_user_id) references public.users(tenant_id, id) on delete restrict,
  check (seq > 0),
  check (seq = 1 or prev_hash is not null),
  check (length(hash) > 20)
);

create table public.signature_records (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  audit_event_id uuid not null,
  signer_user_id uuid not null,
  meaning text not null,
  created_at timestamptz not null default now(),
  unique (tenant_id, id),
  foreign key (tenant_id, audit_event_id) references public.audit_events(tenant_id, id) on delete restrict,
  foreign key (tenant_id, signer_user_id) references public.users(tenant_id, id) on delete restrict
);

create or replace function public.current_tenant_id()
returns uuid
language sql
stable
as $$
  select nullif(auth.jwt() ->> 'tenant_id', '')::uuid;
$$;

create or replace function public.current_user_role()
returns public.app_role
language sql
stable
as $$
  select nullif(auth.jwt() ->> 'user_role', '')::public.app_role;
$$;

create or replace function public.can_operate()
returns boolean
language sql
stable
as $$
  select public.current_user_role() in ('admin', 'manager', 'cta');
$$;

create or replace function public.can_manage_templates()
returns boolean
language sql
stable
as $$
  select public.current_user_role() in ('admin', 'manager');
$$;

create or replace function public.can_manage_users()
returns boolean
language sql
stable
as $$
  select public.current_user_role() = 'admin';
$$;

create or replace function public.custom_access_token_hook(event jsonb)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  claims jsonb;
  app_user record;
begin
  select tenant_id, role
    into app_user
    from public.users
   where auth_user_id = (event ->> 'user_id')::uuid
     and active is true
   limit 1;

  claims := event -> 'claims';

  if app_user.tenant_id is not null then
    claims := jsonb_set(claims, '{tenant_id}', to_jsonb(app_user.tenant_id::text), true);
    claims := jsonb_set(claims, '{user_role}', to_jsonb(app_user.role::text), true);
  end if;

  return jsonb_set(event, '{claims}', claims, true);
end;
$$;

grant usage on schema public to supabase_auth_admin;
grant execute on function public.custom_access_token_hook(jsonb) to supabase_auth_admin;
revoke execute on function public.custom_access_token_hook(jsonb) from authenticated, anon, public;

create or replace function public.prevent_tenant_id_change()
returns trigger
language plpgsql
as $$
begin
  if new.tenant_id is distinct from old.tenant_id then
    raise exception 'tenant_id is immutable';
  end if;
  return new;
end;
$$;

create or replace function public.prevent_update_or_delete()
returns trigger
language plpgsql
as $$
begin
  raise exception '% is append-only/immutable', tg_table_name;
end;
$$;

create or replace function public.validate_requirement_instance()
returns trigger
language plpgsql
as $$
declare
  template record;
begin
  select * into template from public.requirement_templates where id = new.template_id;

  if template.id is null then
    raise exception 'requirement template not found';
  end if;

  if template.tenant_id is not null and template.tenant_id <> new.tenant_id then
    raise exception 'requirement template tenant mismatch';
  end if;

  if template.scope = 'site' and new.person_id is not null then
    raise exception 'site-scoped requirement_instances must not set person_id';
  end if;

  if template.scope = 'person' and new.person_id is null then
    raise exception 'person-scoped requirement_instances must set person_id';
  end if;

  if template.scope = 'person' then
    if not exists (
      select 1
        from public.site_personnel sp
       where sp.tenant_id = new.tenant_id
         and sp.site_id = new.site_id
         and sp.person_id = new.person_id
         and (template.applies_to_role is null or sp.role = template.applies_to_role)
    ) then
      raise exception 'person-scoped requirements require prior site_personnel assignment';
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.validate_document_version()
returns trigger
language plpgsql
as $$
declare
  doc_current_version integer;
begin
  select current_version
    into doc_current_version
    from public.documents
   where tenant_id = new.tenant_id
     and id = new.document_id
   for update;

  if doc_current_version is null then
    raise exception 'document not found for tenant';
  end if;

  if new.version <> doc_current_version + 1 then
    raise exception 'document version must equal current_version + 1';
  end if;

  return new;
end;
$$;

create or replace function public.bump_document_current_version()
returns trigger
language plpgsql
as $$
begin
  update public.documents
     set current_version = new.version
   where tenant_id = new.tenant_id
     and id = new.document_id;
  return new;
end;
$$;

create or replace function public.reject_batched_document_versions()
returns trigger
language plpgsql
as $$
begin
  if exists (
    select 1
      from inserted_versions
     group by tenant_id, document_id
    having count(*) > 1
  ) then
    raise exception 'insert exactly one version per document per statement';
  end if;
  return null;
end;
$$;

create trigger users_tenant_immutable before update on public.users
  for each row execute function public.prevent_tenant_id_change();
create trigger studies_tenant_immutable before update on public.studies
  for each row execute function public.prevent_tenant_id_change();
create trigger organizations_tenant_immutable before update on public.organizations
  for each row execute function public.prevent_tenant_id_change();
create trigger sites_tenant_immutable before update on public.sites
  for each row execute function public.prevent_tenant_id_change();
create trigger people_tenant_immutable before update on public.people
  for each row execute function public.prevent_tenant_id_change();
create trigger site_personnel_tenant_immutable before update on public.site_personnel
  for each row execute function public.prevent_tenant_id_change();
create trigger requirement_templates_tenant_immutable before update on public.requirement_templates
  for each row execute function public.prevent_tenant_id_change();
create trigger requirement_instances_tenant_immutable before update on public.requirement_instances
  for each row execute function public.prevent_tenant_id_change();
create trigger documents_tenant_immutable before update on public.documents
  for each row execute function public.prevent_tenant_id_change();
create trigger requirement_fulfillments_tenant_immutable before update on public.requirement_fulfillments
  for each row execute function public.prevent_tenant_id_change();
create trigger findings_tenant_immutable before update on public.findings
  for each row execute function public.prevent_tenant_id_change();
create trigger finding_evidence_tenant_immutable before update on public.finding_evidence
  for each row execute function public.prevent_tenant_id_change();
create trigger irb_submissions_tenant_immutable before update on public.irb_submissions
  for each row execute function public.prevent_tenant_id_change();
create trigger upload_tokens_tenant_immutable before update on public.upload_tokens
  for each row execute function public.prevent_tenant_id_change();
create trigger signature_records_tenant_immutable before update on public.signature_records
  for each row execute function public.prevent_tenant_id_change();

create trigger requirement_instances_validate before insert or update on public.requirement_instances
  for each row execute function public.validate_requirement_instance();
create trigger document_versions_validate before insert on public.document_versions
  for each row execute function public.validate_document_version();
create trigger document_versions_bump after insert on public.document_versions
  for each row execute function public.bump_document_current_version();
create trigger document_versions_reject_batches after insert on public.document_versions
  referencing new table as inserted_versions
  for each statement execute function public.reject_batched_document_versions();
create trigger document_versions_immutable before update or delete on public.document_versions
  for each row execute function public.prevent_update_or_delete();
create trigger audit_events_append_only before update or delete on public.audit_events
  for each row execute function public.prevent_update_or_delete();

alter table public.tenants enable row level security;
alter table public.users enable row level security;
alter table public.studies enable row level security;
alter table public.organizations enable row level security;
alter table public.sites enable row level security;
alter table public.people enable row level security;
alter table public.site_personnel enable row level security;
alter table public.requirement_templates enable row level security;
alter table public.requirement_instances enable row level security;
alter table public.documents enable row level security;
alter table public.document_versions enable row level security;
alter table public.requirement_fulfillments enable row level security;
alter table public.findings enable row level security;
alter table public.finding_evidence enable row level security;
alter table public.irbs enable row level security;
alter table public.irb_submissions enable row level security;
alter table public.upload_tokens enable row level security;
alter table public.audit_events enable row level security;
alter table public.signature_records enable row level security;

create policy tenants_read on public.tenants for select to authenticated
  using (id = public.current_tenant_id());
create policy users_read on public.users for select to authenticated
  using (tenant_id = public.current_tenant_id());
create policy users_admin_insert on public.users for insert to authenticated
  with check (tenant_id = public.current_tenant_id() and public.can_manage_users());
create policy users_admin_update on public.users for update to authenticated
  using (tenant_id = public.current_tenant_id() and public.can_manage_users())
  with check (tenant_id = public.current_tenant_id() and public.can_manage_users());

create policy studies_read on public.studies for select to authenticated using (tenant_id = public.current_tenant_id());
create policy studies_write on public.studies for all to authenticated
  using (tenant_id = public.current_tenant_id() and public.can_operate())
  with check (tenant_id = public.current_tenant_id() and public.can_operate());
create policy organizations_read on public.organizations for select to authenticated using (tenant_id = public.current_tenant_id());
create policy organizations_write on public.organizations for all to authenticated
  using (tenant_id = public.current_tenant_id() and public.can_operate())
  with check (tenant_id = public.current_tenant_id() and public.can_operate());
create policy sites_read on public.sites for select to authenticated using (tenant_id = public.current_tenant_id());
create policy sites_write on public.sites for all to authenticated
  using (tenant_id = public.current_tenant_id() and public.can_operate())
  with check (tenant_id = public.current_tenant_id() and public.can_operate());
create policy people_read on public.people for select to authenticated using (tenant_id = public.current_tenant_id());
create policy people_write on public.people for all to authenticated
  using (tenant_id = public.current_tenant_id() and public.can_operate())
  with check (tenant_id = public.current_tenant_id() and public.can_operate());
create policy site_personnel_read on public.site_personnel for select to authenticated using (tenant_id = public.current_tenant_id());
create policy site_personnel_write on public.site_personnel for all to authenticated
  using (tenant_id = public.current_tenant_id() and public.can_operate())
  with check (tenant_id = public.current_tenant_id() and public.can_operate());

create policy requirement_templates_read on public.requirement_templates for select to authenticated
  using (tenant_id is null or tenant_id = public.current_tenant_id());
create policy requirement_templates_write on public.requirement_templates for all to authenticated
  using (tenant_id = public.current_tenant_id() and public.can_manage_templates())
  with check (tenant_id = public.current_tenant_id() and public.can_manage_templates());
create policy requirement_instances_read on public.requirement_instances for select to authenticated using (tenant_id = public.current_tenant_id());
create policy requirement_instances_write on public.requirement_instances for all to authenticated
  using (tenant_id = public.current_tenant_id() and public.can_operate())
  with check (tenant_id = public.current_tenant_id() and public.can_operate());
create policy documents_read on public.documents for select to authenticated using (tenant_id = public.current_tenant_id());
create policy documents_write on public.documents for all to authenticated
  using (tenant_id = public.current_tenant_id() and public.can_operate())
  with check (tenant_id = public.current_tenant_id() and public.can_operate());
create policy document_versions_read on public.document_versions for select to authenticated using (tenant_id = public.current_tenant_id());
create policy document_versions_user_insert on public.document_versions for insert to authenticated
  with check (
    tenant_id = public.current_tenant_id() and
    uploaded_via = 'user' and
    uploaded_by = (select id from public.users where auth_user_id = auth.uid() and tenant_id = public.current_tenant_id())
  );
create policy requirement_fulfillments_read on public.requirement_fulfillments for select to authenticated using (tenant_id = public.current_tenant_id());
create policy requirement_fulfillments_write on public.requirement_fulfillments for all to authenticated
  using (tenant_id = public.current_tenant_id() and public.can_operate())
  with check (tenant_id = public.current_tenant_id() and public.can_operate());

create policy findings_read on public.findings for select to authenticated using (tenant_id = public.current_tenant_id());
create policy findings_disposition_update on public.findings for update to authenticated
  using (tenant_id = public.current_tenant_id() and public.can_operate())
  with check (tenant_id = public.current_tenant_id() and public.can_operate());
create policy finding_evidence_read on public.finding_evidence for select to authenticated using (tenant_id = public.current_tenant_id());
create policy irbs_read on public.irbs for select to authenticated using (true);
create policy irb_submissions_read on public.irb_submissions for select to authenticated using (tenant_id = public.current_tenant_id());
create policy irb_submissions_write on public.irb_submissions for all to authenticated
  using (tenant_id = public.current_tenant_id() and public.can_operate())
  with check (tenant_id = public.current_tenant_id() and public.can_operate());
create policy audit_events_read on public.audit_events for select to authenticated using (tenant_id = public.current_tenant_id());
create policy signature_records_read on public.signature_records for select to authenticated using (tenant_id = public.current_tenant_id());

grant select, insert, update, delete on all tables in schema public to authenticated;
revoke all on table public.upload_tokens from anon, authenticated;
revoke update on public.findings from authenticated;
grant update (disposition, disposition_changed_by, disposition_changed_at) on public.findings to authenticated;
revoke insert, update, delete on public.finding_evidence from authenticated;
revoke insert, update, delete on public.audit_events from authenticated;
revoke insert, update, delete on public.signature_records from authenticated;
