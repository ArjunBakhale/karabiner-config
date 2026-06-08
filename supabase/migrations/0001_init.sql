create extension if not exists pgcrypto with schema extensions;
create extension if not exists citext with schema public;
create extension if not exists vector with schema public;

create table public.tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  kind text not null default 'sponsor' check (kind = any (array['sponsor', 'cro'])),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  email public.citext not null,
  full_name text,
  role text not null default 'viewer' check (role = any (array['admin', 'manager', 'cta', 'viewer'])),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, id),
  unique (tenant_id, email)
);

create table public.irbs (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  kind text not null check (kind = any (array['central', 'local'])),
  config_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (name, kind)
);

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  name text not null,
  country text not null,
  ctms_ref text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, id)
);

create table public.documents (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  owner_type text not null check (owner_type = any (array['organization', 'person', 'site', 'study'])),
  owner_id uuid not null,
  doc_type text not null,
  title text,
  status text not null default 'active' check (status = any (array['active', 'superseded', 'withdrawn'])),
  current_version integer not null default 0 check (current_version >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, id)
);

create table public.studies (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  name text not null,
  protocol_version text,
  protocol_doc_id uuid,
  target_ready_date date,
  status text not null default 'active' check (status = any (array['active', 'closed', 'on_hold'])),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, id),
  foreign key (tenant_id, protocol_doc_id) references public.documents(tenant_id, id) on delete restrict
);

create table public.sites (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  study_id uuid not null,
  organization_id uuid not null,
  irb_id uuid references public.irbs(id) on delete set null,
  status text not null default 'selected' check (status = any (array['selected', 'activating', 'ready', 'on_hold', 'withdrawn'])),
  selected_at date,
  projected_ready_date date,
  activated_at date,
  baseline_days integer check (baseline_days is null or baseline_days >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, id),
  unique (tenant_id, study_id, organization_id),
  foreign key (tenant_id, study_id) references public.studies(tenant_id, id) on delete restrict,
  foreign key (tenant_id, organization_id) references public.organizations(tenant_id, id) on delete restrict
);

create table public.people (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  organization_id uuid not null,
  full_name text not null,
  email public.citext,
  npi text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, id),
  foreign key (tenant_id, organization_id) references public.organizations(tenant_id, id) on delete restrict
);

create table public.site_personnel (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  site_id uuid not null,
  person_id uuid not null,
  role text not null check (role = any (array['pi', 'sub_i', 'coordinator', 'pharmacist', 'other'])),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, id),
  unique (tenant_id, site_id, person_id, role),
  foreign key (tenant_id, site_id) references public.sites(tenant_id, id) on delete restrict,
  foreign key (tenant_id, person_id) references public.people(tenant_id, id) on delete restrict
);

create table public.requirement_templates (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references public.tenants(id) on delete cascade,
  name text not null,
  doc_type text not null,
  scope text not null check (scope = any (array['site', 'person'])),
  country text,
  irb_kind text,
  applies_to_role text check (applies_to_role is null or applies_to_role = any (array['pi', 'sub_i', 'coordinator', 'pharmacist', 'other'])),
  rule_json jsonb not null default '{}'::jsonb,
  expiry_relevant boolean not null default false,
  embedding public.vector(1536),
  version integer not null default 1 check (version > 0),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, id),
  check ((scope = 'site' and applies_to_role is null) or scope = 'person')
);

create table public.requirement_instances (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  site_id uuid not null,
  person_id uuid,
  template_id uuid not null references public.requirement_templates(id) on delete restrict,
  status text not null default 'pending' check (status = any (array['pending', 'requested', 'received', 'under_review', 'satisfied', 'rejected', 'waived'])),
  required_by_date date,
  satisfied_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, id),
  unique nulls not distinct (tenant_id, site_id, template_id, person_id),
  foreign key (tenant_id, site_id) references public.sites(tenant_id, id) on delete restrict,
  foreign key (tenant_id, person_id) references public.people(tenant_id, id) on delete restrict,
  check ((status = 'satisfied' and satisfied_at is not null) or status <> 'satisfied')
);

create table public.document_versions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  document_id uuid not null,
  version integer not null check (version > 0),
  storage_path text not null unique,
  content_type text,
  page_count integer check (page_count is null or page_count > 0),
  checksum text not null,
  uploaded_via text not null default 'user' check (uploaded_via = any (array['user', 'token'])),
  uploaded_by uuid,
  uploaded_at timestamptz not null default now(),
  unique (tenant_id, id),
  unique (tenant_id, document_id, version),
  foreign key (tenant_id, document_id) references public.documents(tenant_id, id) on delete restrict,
  foreign key (tenant_id, uploaded_by) references public.users(tenant_id, id) on delete restrict,
  check (storage_path like tenant_id::text || '/%'),
  check ((uploaded_via = 'token' and uploaded_by is null) or (uploaded_via = 'user' and uploaded_by is not null))
);

create table public.requirement_fulfillments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  requirement_instance_id uuid not null,
  document_version_id uuid not null,
  status text not null default 'proposed' check (status = any (array['proposed', 'accepted', 'rejected'])),
  decided_by uuid,
  decided_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, id),
  unique (tenant_id, requirement_instance_id, document_version_id),
  foreign key (tenant_id, requirement_instance_id) references public.requirement_instances(tenant_id, id) on delete restrict,
  foreign key (tenant_id, document_version_id) references public.document_versions(tenant_id, id) on delete restrict,
  foreign key (tenant_id, decided_by) references public.users(tenant_id, id) on delete restrict,
  check ((status = 'proposed' and decided_by is null and decided_at is null) or (status in ('accepted', 'rejected') and decided_by is not null and decided_at is not null))
);

create unique index requirement_fulfillments_one_accepted_per_requirement
  on public.requirement_fulfillments (tenant_id, requirement_instance_id)
  where status = 'accepted';

create table public.upload_tokens (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  site_id uuid not null,
  requirement_instance_id uuid,
  token_hash text not null unique check (length(token_hash) > 20),
  expires_at timestamptz not null,
  used_at timestamptz,
  revoked boolean not null default false,
  created_by uuid,
  created_at timestamptz not null default now(),
  unique (tenant_id, id),
  foreign key (tenant_id, site_id) references public.sites(tenant_id, id) on delete restrict,
  foreign key (tenant_id, requirement_instance_id) references public.requirement_instances(tenant_id, id) on delete restrict,
  foreign key (tenant_id, created_by) references public.users(tenant_id, id) on delete restrict
);

create table public.findings (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  site_id uuid,
  requirement_instance_id uuid,
  type text not null,
  severity text not null default 'warning' check (severity = any (array['info', 'warning', 'blocker'])),
  confidence numeric(4,3) not null check (confidence >= 0 and confidence <= 1),
  detail text,
  source text not null default 'system' check (source = any (array['system', 'user'])),
  disposition text not null default 'open' check (disposition = any (array['open', 'accepted', 'dismissed'])),
  disposition_changed_by uuid,
  disposition_changed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, id),
  foreign key (tenant_id, site_id) references public.sites(tenant_id, id) on delete restrict,
  foreign key (tenant_id, requirement_instance_id) references public.requirement_instances(tenant_id, id) on delete restrict,
  foreign key (tenant_id, disposition_changed_by) references public.users(tenant_id, id) on delete restrict,
  check (site_id is not null or requirement_instance_id is not null),
  check ((disposition = 'open' and disposition_changed_by is null and disposition_changed_at is null) or (disposition in ('accepted', 'dismissed') and disposition_changed_by is not null and disposition_changed_at is not null))
);

create table public.finding_evidence (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  finding_id uuid not null,
  document_version_id uuid not null,
  page integer check (page is null or page > 0),
  field text,
  created_at timestamptz not null default now(),
  unique (tenant_id, id),
  unique nulls not distinct (tenant_id, finding_id, document_version_id, page, field),
  foreign key (tenant_id, finding_id) references public.findings(tenant_id, id) on delete restrict,
  foreign key (tenant_id, document_version_id) references public.document_versions(tenant_id, id) on delete restrict
);

create table public.irb_submissions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  site_id uuid not null,
  irb_id uuid not null references public.irbs(id) on delete restrict,
  status text not null default 'draft' check (status = any (array['draft', 'assembled', 'submitted', 'approved', 'rejected', 'changes_requested'])),
  icf_version text,
  package_storage_path text,
  submitted_at timestamptz,
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, id),
  foreign key (tenant_id, site_id) references public.sites(tenant_id, id) on delete restrict,
  check ((status = 'submitted' and submitted_at is not null) or (status = 'approved' and submitted_at is not null and approved_at is not null) or status <> all (array['submitted', 'approved']))
);

create table public.audit_events (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  seq bigint not null check (seq > 0),
  actor text not null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  payload jsonb not null default '{}'::jsonb,
  prev_hash text,
  hash text not null check (length(hash) > 20),
  created_at timestamptz not null default now(),
  unique (tenant_id, id),
  unique (tenant_id, seq),
  unique (tenant_id, hash),
  foreign key (tenant_id, prev_hash) references public.audit_events(tenant_id, hash) deferrable,
  check ((seq = 1 and prev_hash is null) or (seq > 1 and prev_hash is not null))
);

create unique index audit_events_tenant_prev_hash_uniq
  on public.audit_events (tenant_id, prev_hash)
  where prev_hash is not null;

create table public.signature_records (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  entity_type text not null,
  entity_id uuid not null,
  signer uuid not null,
  meaning text not null,
  signature_hash text,
  signed_at timestamptz not null default now(),
  unique (tenant_id, id),
  foreign key (tenant_id, signer) references public.users(tenant_id, id) on delete restrict
);

create or replace function public.current_tenant_id()
returns uuid
language sql
stable
as $$
  select nullif(auth.jwt() ->> 'tenant_id', '')::uuid;
$$;

create or replace function public.current_user_role()
returns text
language sql
stable
as $$
  select nullif(auth.jwt() ->> 'user_role', '');
$$;

create or replace function public.current_user_is_one_of(allowed_roles text[])
returns boolean
language sql
stable
as $$
  select coalesce(public.current_user_role() = any (allowed_roles), false);
$$;

create or replace function public.custom_access_token_hook(event jsonb)
returns jsonb
language plpgsql
stable
set search_path = public, pg_temp
as $$
declare
  claims jsonb := coalesce(event -> 'claims', '{}'::jsonb);
  v_tenant uuid;
  v_role text;
begin
  select u.tenant_id, u.role
    into v_tenant, v_role
  from public.users u
  where u.id = (event ->> 'user_id')::uuid;

  if v_tenant is not null then
    claims := jsonb_set(claims, '{tenant_id}', to_jsonb(v_tenant::text), true);
    claims := jsonb_set(claims, '{user_role}', to_jsonb(coalesce(v_role, 'viewer')), true);
  end if;

  return jsonb_set(event, '{claims}', claims, true);
end;
$$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.prevent_tenant_id_change()
returns trigger
language plpgsql
as $$
begin
  if new.tenant_id is distinct from old.tenant_id then
    raise exception 'tenant_id cannot be changed on %.%', tg_table_schema, tg_table_name;
  end if;
  return new;
end;
$$;

create or replace function public.prevent_mutation()
returns trigger
language plpgsql
as $$
begin
  raise exception 'append-only/immutable table %: % is not permitted', tg_table_name, tg_op;
end;
$$;

create or replace function public.assert_document_version_insert_consistency()
returns trigger
language plpgsql
as $$
declare
  v_current_version integer;
begin
  select current_version into v_current_version
  from public.documents
  where tenant_id = new.tenant_id and id = new.document_id
  for update;

  if not found then
    return new;
  end if;

  if new.version <> v_current_version + 1 then
    raise exception 'document % expected next version %, got %', new.document_id, v_current_version + 1, new.version;
  end if;

  return new;
end;
$$;

create or replace function public.bump_document_current_version()
returns trigger
language plpgsql
as $$
begin
  perform set_config('greenlight.allow_current_version_update', 'on', true);
  update public.documents set current_version = new.version where tenant_id = new.tenant_id and id = new.document_id;
  perform set_config('greenlight.allow_current_version_update', 'off', true);
  return new;
end;
$$;

create or replace function public.enforce_audit_event_chain()
returns trigger
language plpgsql
as $$
declare
  v_prev_seq bigint;
  v_prev_hash text;
begin
  perform pg_advisory_xact_lock(hashtext('audit_events'), hashtext(new.tenant_id::text));
  if new.seq = 1 then
    if new.prev_hash is not null then
      raise exception 'first audit event for tenant % must not have prev_hash', new.tenant_id;
    end if;
    if exists (select 1 from public.audit_events where tenant_id = new.tenant_id) then
      raise exception 'tenant % already has audit events; seq 1 cannot be inserted again', new.tenant_id;
    end if;
  else
    select seq, hash into v_prev_seq, v_prev_hash
    from public.audit_events
    where tenant_id = new.tenant_id
    order by seq desc
    limit 1;

    if v_prev_seq is null then
      raise exception 'tenant % audit chain must start at seq 1', new.tenant_id;
    end if;
    if v_prev_seq <> new.seq - 1 or v_prev_hash <> new.prev_hash then
      raise exception 'audit chain mismatch for tenant %', new.tenant_id;
    end if;
  end if;
  return new;
end;
$$;

create or replace function public.assert_requirement_instance_consistency()
returns trigger
language plpgsql
as $$
declare
  v_template_tenant uuid;
  v_scope text;
  v_applies_role text;
  v_assignment_ok boolean;
begin
  select tenant_id, scope, applies_to_role into v_template_tenant, v_scope, v_applies_role
  from public.requirement_templates
  where id = new.template_id;

  if not found then
    return new;
  end if;
  if v_template_tenant is not null and v_template_tenant <> new.tenant_id then
    raise exception 'requirement template % does not belong to tenant %', new.template_id, new.tenant_id;
  end if;
  if v_scope = 'site' and new.person_id is not null then
    raise exception 'site-scoped requirement template % cannot have person_id %', new.template_id, new.person_id;
  end if;
  if v_scope = 'person' and new.person_id is null then
    raise exception 'person-scoped requirement template % requires person_id', new.template_id;
  end if;
  if v_scope = 'person' then
    select exists (
      select 1
      from public.site_personnel sp
      where sp.tenant_id = new.tenant_id
        and sp.site_id = new.site_id
        and sp.person_id = new.person_id
        and (v_applies_role is null or sp.role = v_applies_role)
    ) into v_assignment_ok;

    if not v_assignment_ok then
      raise exception 'person % is not assigned to site % with required role %', new.person_id, new.site_id, coalesce(v_applies_role, '<any>');
    end if;
  end if;
  return new;
end;
$$;

create or replace function public.assert_upload_token_consistency()
returns trigger
language plpgsql
as $$
declare
  v_requirement_site uuid;
begin
  if new.requirement_instance_id is null then
    return new;
  end if;

  select site_id into v_requirement_site
  from public.requirement_instances
  where tenant_id = new.tenant_id and id = new.requirement_instance_id;

  if v_requirement_site is not null and v_requirement_site <> new.site_id then
    raise exception 'upload token requirement % belongs to site %, not site %', new.requirement_instance_id, v_requirement_site, new.site_id;
  end if;
  return new;
end;
$$;

create trigger document_versions_insert_consistency before insert on public.document_versions for each row execute function public.assert_document_version_insert_consistency();
create trigger document_versions_bump_document_current_version after insert on public.document_versions for each row execute function public.bump_document_current_version();
create trigger document_versions_no_update before update on public.document_versions for each row execute function public.prevent_mutation();
create trigger document_versions_no_delete before delete on public.document_versions for each row execute function public.prevent_mutation();
create trigger audit_events_chain before insert on public.audit_events for each row execute function public.enforce_audit_event_chain();
create trigger audit_events_no_update before update on public.audit_events for each row execute function public.prevent_mutation();
create trigger audit_events_no_delete before delete on public.audit_events for each row execute function public.prevent_mutation();
create trigger requirement_instances_consistency before insert or update of tenant_id, site_id, person_id, template_id on public.requirement_instances for each row execute function public.assert_requirement_instance_consistency();
create trigger upload_tokens_consistency before insert or update of tenant_id, site_id, requirement_instance_id on public.upload_tokens for each row execute function public.assert_upload_token_consistency();

create trigger tenants_set_updated_at before update on public.tenants for each row execute function public.set_updated_at();
create trigger users_set_updated_at before update on public.users for each row execute function public.set_updated_at();
create trigger organizations_set_updated_at before update on public.organizations for each row execute function public.set_updated_at();
create trigger documents_set_updated_at before update on public.documents for each row execute function public.set_updated_at();
create trigger studies_set_updated_at before update on public.studies for each row execute function public.set_updated_at();
create trigger sites_set_updated_at before update on public.sites for each row execute function public.set_updated_at();
create trigger people_set_updated_at before update on public.people for each row execute function public.set_updated_at();
create trigger site_personnel_set_updated_at before update on public.site_personnel for each row execute function public.set_updated_at();
create trigger requirement_templates_set_updated_at before update on public.requirement_templates for each row execute function public.set_updated_at();
create trigger requirement_instances_set_updated_at before update on public.requirement_instances for each row execute function public.set_updated_at();
create trigger requirement_fulfillments_set_updated_at before update on public.requirement_fulfillments for each row execute function public.set_updated_at();
create trigger findings_set_updated_at before update on public.findings for each row execute function public.set_updated_at();
create trigger irb_submissions_set_updated_at before update on public.irb_submissions for each row execute function public.set_updated_at();

create trigger users_prevent_tenant_id_change before update on public.users for each row execute function public.prevent_tenant_id_change();
create trigger organizations_prevent_tenant_id_change before update on public.organizations for each row execute function public.prevent_tenant_id_change();
create trigger documents_prevent_tenant_id_change before update on public.documents for each row execute function public.prevent_tenant_id_change();
create trigger studies_prevent_tenant_id_change before update on public.studies for each row execute function public.prevent_tenant_id_change();
create trigger sites_prevent_tenant_id_change before update on public.sites for each row execute function public.prevent_tenant_id_change();
create trigger people_prevent_tenant_id_change before update on public.people for each row execute function public.prevent_tenant_id_change();
create trigger site_personnel_prevent_tenant_id_change before update on public.site_personnel for each row execute function public.prevent_tenant_id_change();
create trigger requirement_templates_prevent_tenant_id_change before update on public.requirement_templates for each row execute function public.prevent_tenant_id_change();
create trigger requirement_instances_prevent_tenant_id_change before update on public.requirement_instances for each row execute function public.prevent_tenant_id_change();
create trigger requirement_fulfillments_prevent_tenant_id_change before update on public.requirement_fulfillments for each row execute function public.prevent_tenant_id_change();
create trigger upload_tokens_prevent_tenant_id_change before update on public.upload_tokens for each row execute function public.prevent_tenant_id_change();
create trigger findings_prevent_tenant_id_change before update on public.findings for each row execute function public.prevent_tenant_id_change();
create trigger finding_evidence_prevent_tenant_id_change before update on public.finding_evidence for each row execute function public.prevent_tenant_id_change();
create trigger irb_submissions_prevent_tenant_id_change before update on public.irb_submissions for each row execute function public.prevent_tenant_id_change();
create trigger audit_events_prevent_tenant_id_change before update on public.audit_events for each row execute function public.prevent_tenant_id_change();
create trigger signature_records_prevent_tenant_id_change before update on public.signature_records for each row execute function public.prevent_tenant_id_change();

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
alter table public.upload_tokens enable row level security;
alter table public.findings enable row level security;
alter table public.finding_evidence enable row level security;
alter table public.irbs enable row level security;
alter table public.irb_submissions enable row level security;
alter table public.audit_events enable row level security;
alter table public.signature_records enable row level security;

create policy tenants_select on public.tenants for select to authenticated using (id = (select public.current_tenant_id()));
create policy tenants_update_admin on public.tenants for update to authenticated using (id = (select public.current_tenant_id()) and (select public.current_user_is_one_of(array['admin']))) with check (id = (select public.current_tenant_id()));

create policy users_auth_hook_select on public.users for select to supabase_auth_admin using (true);
create policy tenant_select on public.users for select to authenticated using (tenant_id = (select public.current_tenant_id()));
create policy users_insert_admin on public.users for insert to authenticated with check (tenant_id = (select public.current_tenant_id()) and (select public.current_user_is_one_of(array['admin'])));
create policy users_update_admin on public.users for update to authenticated using (tenant_id = (select public.current_tenant_id()) and (select public.current_user_is_one_of(array['admin']))) with check (tenant_id = (select public.current_tenant_id()));

create policy irbs_select on public.irbs for select to authenticated using (true);

create policy templates_select on public.requirement_templates for select to authenticated using (tenant_id is null or tenant_id = (select public.current_tenant_id()));
create policy templates_insert_admin_manager on public.requirement_templates for insert to authenticated with check (tenant_id = (select public.current_tenant_id()) and (select public.current_user_is_one_of(array['admin', 'manager'])));
create policy templates_update_admin_manager on public.requirement_templates for update to authenticated using (tenant_id = (select public.current_tenant_id()) and (select public.current_user_is_one_of(array['admin', 'manager']))) with check (tenant_id = (select public.current_tenant_id()));

create policy document_versions_insert_user_upload on public.document_versions for insert to authenticated with check (tenant_id = (select public.current_tenant_id()) and (select public.current_user_is_one_of(array['admin', 'manager', 'cta'])) and uploaded_via = 'user' and uploaded_by = auth.uid());
create policy findings_update_disposition on public.findings for update to authenticated using (tenant_id = (select public.current_tenant_id()) and (select public.current_user_is_one_of(array['admin', 'manager', 'cta']))) with check (tenant_id = (select public.current_tenant_id()) and (disposition = 'open' or disposition_changed_by = auth.uid()));

create policy tenant_select on public.studies for select to authenticated using (tenant_id = (select public.current_tenant_id()));
create policy tenant_insert_ops on public.studies for insert to authenticated with check (tenant_id = (select public.current_tenant_id()) and (select public.current_user_is_one_of(array['admin', 'manager', 'cta'])));
create policy tenant_update_ops on public.studies for update to authenticated using (tenant_id = (select public.current_tenant_id()) and (select public.current_user_is_one_of(array['admin', 'manager', 'cta']))) with check (tenant_id = (select public.current_tenant_id()));

create policy tenant_select on public.organizations for select to authenticated using (tenant_id = (select public.current_tenant_id()));
create policy tenant_insert_ops on public.organizations for insert to authenticated with check (tenant_id = (select public.current_tenant_id()) and (select public.current_user_is_one_of(array['admin', 'manager', 'cta'])));
create policy tenant_update_ops on public.organizations for update to authenticated using (tenant_id = (select public.current_tenant_id()) and (select public.current_user_is_one_of(array['admin', 'manager', 'cta']))) with check (tenant_id = (select public.current_tenant_id()));

create policy tenant_select on public.sites for select to authenticated using (tenant_id = (select public.current_tenant_id()));
create policy tenant_insert_ops on public.sites for insert to authenticated with check (tenant_id = (select public.current_tenant_id()) and (select public.current_user_is_one_of(array['admin', 'manager', 'cta'])));
create policy tenant_update_ops on public.sites for update to authenticated using (tenant_id = (select public.current_tenant_id()) and (select public.current_user_is_one_of(array['admin', 'manager', 'cta']))) with check (tenant_id = (select public.current_tenant_id()));

create policy tenant_select on public.people for select to authenticated using (tenant_id = (select public.current_tenant_id()));
create policy tenant_insert_ops on public.people for insert to authenticated with check (tenant_id = (select public.current_tenant_id()) and (select public.current_user_is_one_of(array['admin', 'manager', 'cta'])));
create policy tenant_update_ops on public.people for update to authenticated using (tenant_id = (select public.current_tenant_id()) and (select public.current_user_is_one_of(array['admin', 'manager', 'cta']))) with check (tenant_id = (select public.current_tenant_id()));

create policy tenant_select on public.site_personnel for select to authenticated using (tenant_id = (select public.current_tenant_id()));
create policy tenant_insert_ops on public.site_personnel for insert to authenticated with check (tenant_id = (select public.current_tenant_id()) and (select public.current_user_is_one_of(array['admin', 'manager', 'cta'])));
create policy tenant_update_ops on public.site_personnel for update to authenticated using (tenant_id = (select public.current_tenant_id()) and (select public.current_user_is_one_of(array['admin', 'manager', 'cta']))) with check (tenant_id = (select public.current_tenant_id()));

create policy tenant_select on public.documents for select to authenticated using (tenant_id = (select public.current_tenant_id()));
create policy tenant_insert_ops on public.documents for insert to authenticated with check (tenant_id = (select public.current_tenant_id()) and (select public.current_user_is_one_of(array['admin', 'manager', 'cta'])));
create policy tenant_update_ops on public.documents for update to authenticated using (tenant_id = (select public.current_tenant_id()) and (select public.current_user_is_one_of(array['admin', 'manager', 'cta']))) with check (tenant_id = (select public.current_tenant_id()));

create policy tenant_select on public.document_versions for select to authenticated using (tenant_id = (select public.current_tenant_id()));
create policy tenant_select on public.requirement_instances for select to authenticated using (tenant_id = (select public.current_tenant_id()));
create policy tenant_insert_ops on public.requirement_instances for insert to authenticated with check (tenant_id = (select public.current_tenant_id()) and (select public.current_user_is_one_of(array['admin', 'manager', 'cta'])));
create policy tenant_update_ops on public.requirement_instances for update to authenticated using (tenant_id = (select public.current_tenant_id()) and (select public.current_user_is_one_of(array['admin', 'manager', 'cta']))) with check (tenant_id = (select public.current_tenant_id()));

create policy tenant_select on public.requirement_fulfillments for select to authenticated using (tenant_id = (select public.current_tenant_id()));
create policy tenant_insert_ops on public.requirement_fulfillments for insert to authenticated with check (tenant_id = (select public.current_tenant_id()) and (select public.current_user_is_one_of(array['admin', 'manager', 'cta'])));
create policy tenant_update_ops on public.requirement_fulfillments for update to authenticated using (tenant_id = (select public.current_tenant_id()) and (select public.current_user_is_one_of(array['admin', 'manager', 'cta']))) with check (tenant_id = (select public.current_tenant_id()));

create policy tenant_select on public.findings for select to authenticated using (tenant_id = (select public.current_tenant_id()));
create policy tenant_select on public.finding_evidence for select to authenticated using (tenant_id = (select public.current_tenant_id()));
create policy tenant_select on public.irb_submissions for select to authenticated using (tenant_id = (select public.current_tenant_id()));
create policy tenant_insert_ops on public.irb_submissions for insert to authenticated with check (tenant_id = (select public.current_tenant_id()) and (select public.current_user_is_one_of(array['admin', 'manager', 'cta'])));
create policy tenant_update_ops on public.irb_submissions for update to authenticated using (tenant_id = (select public.current_tenant_id()) and (select public.current_user_is_one_of(array['admin', 'manager', 'cta']))) with check (tenant_id = (select public.current_tenant_id()));
create policy tenant_select on public.audit_events for select to authenticated using (tenant_id = (select public.current_tenant_id()));
create policy tenant_select on public.signature_records for select to authenticated using (tenant_id = (select public.current_tenant_id()));

revoke all on public.upload_tokens from anon, authenticated;
grant execute on function public.custom_access_token_hook(jsonb) to supabase_auth_admin;
