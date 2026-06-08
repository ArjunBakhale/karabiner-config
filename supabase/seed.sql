insert into public.tenants (id, name, slug)
values ('00000000-0000-4000-8000-000000000001', 'Greenlight Demo Sponsor', 'greenlight-demo')
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

insert into public.users (id, tenant_id, auth_user_id, email, full_name, role)
values
  ('00000000-0000-4000-8000-000000000201', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000101', 'admin@greenlight.local', 'Alex Admin', 'admin'),
  ('00000000-0000-4000-8000-000000000202', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000102', 'manager@greenlight.local', 'Morgan Manager', 'manager'),
  ('00000000-0000-4000-8000-000000000203', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000103', 'cta@greenlight.local', 'Casey CTA', 'cta')
on conflict (id) do nothing;

insert into public.irbs (id, name, kind, website)
values
  ('00000000-0000-4000-8000-000000000301', 'WCG IRB', 'central', 'https://www.wcgclinical.com'),
  ('00000000-0000-4000-8000-000000000302', 'Advarra IRB', 'central', 'https://www.advarra.com')
on conflict (name) do nothing;

insert into public.studies (id, tenant_id, protocol_number, title, phase)
values ('00000000-0000-4000-8000-000000000401', '00000000-0000-4000-8000-000000000001', 'GL-101', 'A Phase 2 Study of GL-101 in Solid Tumors', '2')
on conflict (tenant_id, protocol_number) do nothing;

insert into public.organizations (id, tenant_id, name, kind, country)
values
  ('00000000-0000-4000-8000-000000000501', '00000000-0000-4000-8000-000000000001', 'Northstar Research Institute', 'site', 'US'),
  ('00000000-0000-4000-8000-000000000502', '00000000-0000-4000-8000-000000000001', 'Lakeside Oncology Center', 'site', 'US')
on conflict (id) do nothing;

insert into public.sites (id, tenant_id, study_id, organization_id, site_number, status, selected_at)
values
  ('00000000-0000-4000-8000-000000000601', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000401', '00000000-0000-4000-8000-000000000501', '001', 'collecting', now()),
  ('00000000-0000-4000-8000-000000000602', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000401', '00000000-0000-4000-8000-000000000502', '002', 'selected', now()),
  ('00000000-0000-4000-8000-000000000603', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000401', '00000000-0000-4000-8000-000000000501', '003', 'reviewing', now()),
  ('00000000-0000-4000-8000-000000000604', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000401', '00000000-0000-4000-8000-000000000502', '004', 'collecting', now()),
  ('00000000-0000-4000-8000-000000000605', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000401', '00000000-0000-4000-8000-000000000501', '005', 'selected', now()),
  ('00000000-0000-4000-8000-000000000606', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000401', '00000000-0000-4000-8000-000000000502', '006', 'selected', now())
on conflict (tenant_id, study_id, site_number) do nothing;

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
  ('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000602', '00000000-0000-4000-8000-000000000704', 'coordinator'),
  ('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000603', '00000000-0000-4000-8000-000000000701', 'pi'),
  ('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000604', '00000000-0000-4000-8000-000000000703', 'pi')
on conflict (tenant_id, site_id, person_id, role) do nothing;

insert into public.requirement_templates (id, tenant_id, code, name, scope, applies_to_role, description)
values
  ('00000000-0000-4000-8000-000000000801', null, 'REG-1572', 'FDA Form 1572', 'site', null, 'Site-level investigator statement.'),
  ('00000000-0000-4000-8000-000000000802', null, 'REG-ICF', 'Approved Informed Consent Form', 'site', null, 'Current IRB-approved ICF.'),
  ('00000000-0000-4000-8000-000000000803', null, 'REG-CV-PI', 'Principal Investigator CV', 'person', 'pi', 'Signed and dated PI curriculum vitae.'),
  ('00000000-0000-4000-8000-000000000804', null, 'REG-ML-PI', 'Principal Investigator Medical License', 'person', 'pi', 'Current PI medical license.'),
  ('00000000-0000-4000-8000-000000000805', null, 'REG-GCP', 'GCP Training Certificate', 'person', null, 'Current GCP training evidence.')
on conflict (id) do nothing;

insert into public.requirement_instances (id, tenant_id, site_id, template_id, person_id, status)
values
  ('00000000-0000-4000-8000-000000000901', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000601', '00000000-0000-4000-8000-000000000801', null, 'pending_review'),
  ('00000000-0000-4000-8000-000000000902', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000601', '00000000-0000-4000-8000-000000000802', null, 'missing'),
  ('00000000-0000-4000-8000-000000000903', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000601', '00000000-0000-4000-8000-000000000803', '00000000-0000-4000-8000-000000000701', 'pending_review'),
  ('00000000-0000-4000-8000-000000000904', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000602', '00000000-0000-4000-8000-000000000801', null, 'missing'),
  ('00000000-0000-4000-8000-000000000905', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000602', '00000000-0000-4000-8000-000000000803', '00000000-0000-4000-8000-000000000703', 'missing')
on conflict (id) do nothing;

insert into public.documents (id, tenant_id, owner_type, owner_id, title, document_type)
values
  ('00000000-0000-4000-8000-000000001001', '00000000-0000-4000-8000-000000000001', 'site', '00000000-0000-4000-8000-000000000601', 'Site 001 Form 1572', '1572'),
  ('00000000-0000-4000-8000-000000001002', '00000000-0000-4000-8000-000000000001', 'person', '00000000-0000-4000-8000-000000000701', 'Dr. Shah CV', 'cv')
on conflict (id) do nothing;

insert into public.document_versions (id, tenant_id, document_id, version, storage_path, checksum, mime_type, byte_size, uploaded_via, uploaded_by, metadata)
values ('00000000-0000-4000-8000-000000001101', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000001001', 1, '00000000-0000-4000-8000-000000000001/documents/site-001/form-1572-v1.pdf', '9d1f0ec65db07f0c7c2fcbd5d9fbef6937e0b6047a3f9f018f3d25b734f4f7a1', 'application/pdf', 123456, 'user', '00000000-0000-4000-8000-000000000201', '{"seeded":true}'::jsonb)
on conflict (tenant_id, document_id, version) do nothing;

insert into public.document_versions (id, tenant_id, document_id, version, storage_path, checksum, mime_type, byte_size, uploaded_via, uploaded_by, metadata)
values ('00000000-0000-4000-8000-000000001102', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000001002', 1, '00000000-0000-4000-8000-000000000001/documents/people/dr-shah-cv-v1.pdf', '4d967f208032cfbdf7f58d3dc00ed90d94b6d7e53258a93ff8a6fbdf70560dfe', 'application/pdf', 98211, 'user', '00000000-0000-4000-8000-000000000201', '{"seeded":true}'::jsonb)
on conflict (tenant_id, document_id, version) do nothing;

insert into public.requirement_fulfillments (tenant_id, requirement_instance_id, document_version_id, status)
values
  ('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000901', '00000000-0000-4000-8000-000000001101', 'proposed'),
  ('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000903', '00000000-0000-4000-8000-000000001102', 'proposed')
on conflict do nothing;

insert into public.upload_tokens (tenant_id, token_hash, document_id, owner_type, owner_id, purpose, expires_at, created_by)
values ('00000000-0000-4000-8000-000000000001', 'seeded-upload-token-hash-length-over-20', null, 'site', '00000000-0000-4000-8000-000000000601', 'seeded upload', now() + interval '30 days', '00000000-0000-4000-8000-000000000201')
on conflict (token_hash) do nothing;
