insert into public.tenants (id, name, kind)
values ('00000000-0000-4000-8000-000000000001', 'Greenlight Demo Sponsor', 'sponsor')
on conflict (id) do nothing;

insert into auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  is_super_admin,
  created_at,
  updated_at
)
values
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-4000-8000-000000000101', 'authenticated', 'authenticated', 'admin@greenlight.local', crypt('greenlight-demo-password', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Alex Admin"}'::jsonb, false, now(), now()),
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-4000-8000-000000000102', 'authenticated', 'authenticated', 'manager@greenlight.local', crypt('greenlight-demo-password', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Morgan Manager"}'::jsonb, false, now(), now()),
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-4000-8000-000000000103', 'authenticated', 'authenticated', 'cta@greenlight.local', crypt('greenlight-demo-password', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Casey CTA"}'::jsonb, false, now(), now())
on conflict (id) do nothing;

insert into auth.identities (
  provider_id,
  user_id,
  identity_data,
  provider,
  last_sign_in_at,
  created_at,
  updated_at,
  id
)
values
  ('00000000-0000-4000-8000-000000000101', '00000000-0000-4000-8000-000000000101', '{"sub":"00000000-0000-4000-8000-000000000101","email":"admin@greenlight.local"}'::jsonb, 'email', now(), now(), now(), gen_random_uuid()),
  ('00000000-0000-4000-8000-000000000102', '00000000-0000-4000-8000-000000000102', '{"sub":"00000000-0000-4000-8000-000000000102","email":"manager@greenlight.local"}'::jsonb, 'email', now(), now(), now(), gen_random_uuid()),
  ('00000000-0000-4000-8000-000000000103', '00000000-0000-4000-8000-000000000103', '{"sub":"00000000-0000-4000-8000-000000000103","email":"cta@greenlight.local"}'::jsonb, 'email', now(), now(), now(), gen_random_uuid())
on conflict (provider, provider_id) do nothing;

insert into public.users (id, tenant_id, email, full_name, role)
values
  ('00000000-0000-4000-8000-000000000101', '00000000-0000-4000-8000-000000000001', 'admin@greenlight.local', 'Alex Admin', 'admin'),
  ('00000000-0000-4000-8000-000000000102', '00000000-0000-4000-8000-000000000001', 'manager@greenlight.local', 'Morgan Manager', 'manager'),
  ('00000000-0000-4000-8000-000000000103', '00000000-0000-4000-8000-000000000001', 'cta@greenlight.local', 'Casey CTA', 'cta')
on conflict (id) do nothing;

insert into public.irbs (id, name, kind, config_json)
values
  ('00000000-0000-4000-8000-000000000301', 'WCG IRB', 'central', '{"website":"https://www.wcgclinical.com"}'::jsonb),
  ('00000000-0000-4000-8000-000000000302', 'Advarra IRB', 'central', '{"website":"https://www.advarra.com"}'::jsonb)
on conflict (name, kind) do nothing;

insert into public.organizations (id, tenant_id, name, country, ctms_ref)
values
  ('00000000-0000-4000-8000-000000000501', '00000000-0000-4000-8000-000000000001', 'Northstar Research Institute', 'US', 'SITE-001'),
  ('00000000-0000-4000-8000-000000000502', '00000000-0000-4000-8000-000000000001', 'Lakeside Oncology Center', 'US', 'SITE-002'),
  ('00000000-0000-4000-8000-000000000503', '00000000-0000-4000-8000-000000000001', 'Metro Clinical Research', 'US', 'SITE-003'),
  ('00000000-0000-4000-8000-000000000504', '00000000-0000-4000-8000-000000000001', 'Cascadia Cancer Institute', 'US', 'SITE-004'),
  ('00000000-0000-4000-8000-000000000505', '00000000-0000-4000-8000-000000000001', 'Redwood Therapeutics Site', 'US', 'SITE-005'),
  ('00000000-0000-4000-8000-000000000506', '00000000-0000-4000-8000-000000000001', 'Summit Research Group', 'US', 'SITE-006')
on conflict (id) do nothing;

insert into public.studies (id, tenant_id, name, protocol_version, target_ready_date, status)
values ('00000000-0000-4000-8000-000000000401', '00000000-0000-4000-8000-000000000001', 'A Phase 2 Study of GL-101 in Solid Tumors', 'GL-101 v1.0', current_date + 45, 'active')
on conflict (id) do nothing;

insert into public.sites (id, tenant_id, study_id, organization_id, irb_id, status, selected_at, projected_ready_date, baseline_days)
values
  ('00000000-0000-4000-8000-000000000601', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000401', '00000000-0000-4000-8000-000000000501', '00000000-0000-4000-8000-000000000301', 'activating', current_date - 7, current_date + 21, 60),
  ('00000000-0000-4000-8000-000000000602', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000401', '00000000-0000-4000-8000-000000000502', '00000000-0000-4000-8000-000000000302', 'selected', current_date - 5, current_date + 25, 55),
  ('00000000-0000-4000-8000-000000000603', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000401', '00000000-0000-4000-8000-000000000503', '00000000-0000-4000-8000-000000000301', 'activating', current_date - 4, current_date + 28, 50),
  ('00000000-0000-4000-8000-000000000604', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000401', '00000000-0000-4000-8000-000000000504', '00000000-0000-4000-8000-000000000302', 'selected', current_date - 3, current_date + 30, 52),
  ('00000000-0000-4000-8000-000000000605', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000401', '00000000-0000-4000-8000-000000000505', '00000000-0000-4000-8000-000000000301', 'selected', current_date - 2, current_date + 35, 57),
  ('00000000-0000-4000-8000-000000000606', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000401', '00000000-0000-4000-8000-000000000506', '00000000-0000-4000-8000-000000000302', 'selected', current_date - 1, current_date + 40, 58)
on conflict (id) do nothing;

insert into public.people (id, tenant_id, organization_id, full_name, email, npi)
values
  ('00000000-0000-4000-8000-000000000701', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000501', 'Dr. Priya Shah', 'priya.shah@northstar.example', '1000000001'),
  ('00000000-0000-4000-8000-000000000702', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000501', 'Sam Lee', 'sam.lee@northstar.example', null),
  ('00000000-0000-4000-8000-000000000703', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000502', 'Dr. Elena Morales', 'elena.morales@lakeside.example', '1000000002'),
  ('00000000-0000-4000-8000-000000000704', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000502', 'Jordan Kim', 'jordan.kim@lakeside.example', null)
on conflict (id) do nothing;

insert into public.site_personnel (tenant_id, site_id, person_id, role)
values
  ('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000601', '00000000-0000-4000-8000-000000000701', 'pi'),
  ('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000601', '00000000-0000-4000-8000-000000000702', 'coordinator'),
  ('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000602', '00000000-0000-4000-8000-000000000703', 'pi'),
  ('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000602', '00000000-0000-4000-8000-000000000704', 'coordinator')
on conflict (tenant_id, site_id, person_id, role) do nothing;

insert into public.requirement_templates (id, tenant_id, name, doc_type, scope, applies_to_role, country, irb_kind, rule_json, expiry_relevant)
values
  ('00000000-0000-4000-8000-000000000801', null, 'FDA Form 1572', '1572', 'site', null, 'US', null, '{"required":true}'::jsonb, false),
  ('00000000-0000-4000-8000-000000000802', null, 'Approved Informed Consent Form', 'icf', 'site', null, 'US', null, '{"required":true}'::jsonb, false),
  ('00000000-0000-4000-8000-000000000803', null, 'Principal Investigator CV', 'cv', 'person', 'pi', 'US', null, '{"required":true}'::jsonb, true),
  ('00000000-0000-4000-8000-000000000804', null, 'Principal Investigator Medical License', 'medical_license', 'person', 'pi', 'US', null, '{"required":true}'::jsonb, true),
  ('00000000-0000-4000-8000-000000000805', null, 'GCP Training Certificate', 'gcp', 'person', null, 'US', null, '{"required":true}'::jsonb, true)
on conflict (id) do nothing;

insert into public.requirement_instances (id, tenant_id, site_id, person_id, template_id, status)
values
  ('00000000-0000-4000-8000-000000000901', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000601', null, '00000000-0000-4000-8000-000000000801', 'received'),
  ('00000000-0000-4000-8000-000000000902', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000601', null, '00000000-0000-4000-8000-000000000802', 'pending'),
  ('00000000-0000-4000-8000-000000000903', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000601', '00000000-0000-4000-8000-000000000701', '00000000-0000-4000-8000-000000000803', 'received'),
  ('00000000-0000-4000-8000-000000000904', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000602', null, '00000000-0000-4000-8000-000000000801', 'pending'),
  ('00000000-0000-4000-8000-000000000905', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000602', '00000000-0000-4000-8000-000000000703', '00000000-0000-4000-8000-000000000803', 'pending')
on conflict (id) do nothing;

insert into public.documents (id, tenant_id, owner_type, owner_id, doc_type, title)
values
  ('00000000-0000-4000-8000-000000001001', '00000000-0000-4000-8000-000000000001', 'site', '00000000-0000-4000-8000-000000000601', '1572', 'Site 001 Form 1572'),
  ('00000000-0000-4000-8000-000000001002', '00000000-0000-4000-8000-000000000001', 'person', '00000000-0000-4000-8000-000000000701', 'cv', 'Dr. Shah CV')
on conflict (id) do nothing;

insert into public.document_versions (id, tenant_id, document_id, version, storage_path, content_type, page_count, checksum, uploaded_via, uploaded_by)
values ('00000000-0000-4000-8000-000000001101', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000001001', 1, '00000000-0000-4000-8000-000000000001/documents/site-001/form-1572-v1.pdf', 'application/pdf', 4, '9d1f0ec65db07f0c7c2fcbd5d9fbef6937e0b6047a3f9f018f3d25b734f4f7a1', 'user', '00000000-0000-4000-8000-000000000101')
on conflict (storage_path) do nothing;

insert into public.document_versions (id, tenant_id, document_id, version, storage_path, content_type, page_count, checksum, uploaded_via, uploaded_by)
values ('00000000-0000-4000-8000-000000001102', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000001002', 1, '00000000-0000-4000-8000-000000000001/documents/people/dr-shah-cv-v1.pdf', 'application/pdf', 6, '4d967f208032cfbdf7f58d3dc00ed90d94b6d7e53258a93ff8a6fbdf70560dfe', 'user', '00000000-0000-4000-8000-000000000101')
on conflict (storage_path) do nothing;

insert into public.requirement_fulfillments (tenant_id, requirement_instance_id, document_version_id, status)
values
  ('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000901', '00000000-0000-4000-8000-000000001101', 'proposed'),
  ('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000903', '00000000-0000-4000-8000-000000001102', 'proposed')
on conflict do nothing;

insert into public.upload_tokens (tenant_id, site_id, requirement_instance_id, token_hash, expires_at, created_by)
values ('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000601', '00000000-0000-4000-8000-000000000902', 'seeded-upload-token-hash-length-over-20', now() + interval '30 days', '00000000-0000-4000-8000-000000000101')
on conflict (token_hash) do nothing;
