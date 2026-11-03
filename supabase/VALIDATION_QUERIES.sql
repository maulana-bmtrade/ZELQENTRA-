-- Run after applying both migrations in Supabase SQL Editor.
-- These are read-only diagnostics; inspect every returned result.

-- 1) Expected application tables (15 rows).
select table_name
from information_schema.tables
where table_schema='public'
  and table_name in ('users','companies','company_members','business_profiles','products','product_categories','buyer_requests','rfqs','quotations','conversations','messages','notifications','verification_documents','verification_records','reports')
order by table_name;

-- 2) Primary/foreign keys and constraints.
select tc.table_name, tc.constraint_name, tc.constraint_type
from information_schema.table_constraints tc
where tc.constraint_schema='public'
  and tc.table_name in ('users','companies','company_members','business_profiles','products','product_categories','buyer_requests','rfqs','quotations','conversations','messages','notifications','verification_documents','verification_records','reports')
order by tc.table_name, tc.constraint_type, tc.constraint_name;

-- 3) RLS enabled on all 15 tables.
select c.relname as table_name, c.relrowsecurity as rls_enabled, c.relforcerowsecurity as force_rls
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relkind='r'
  and c.relname in ('users','companies','company_members','business_profiles','products','product_categories','buyer_requests','rfqs','quotations','conversations','messages','notifications','verification_documents','verification_records','reports')
order by c.relname;

-- 4) Index inventory.
select tablename, indexname, indexdef
from pg_indexes where schemaname='public'
order by tablename,indexname;

-- 5) Updated-at triggers and auth profile trigger.
select event_object_schema, event_object_table, trigger_name, action_timing, event_manipulation
from information_schema.triggers
where (event_object_schema='public' and event_object_table in ('users','companies','business_profiles','product_categories','products','buyer_requests','rfqs','quotations','conversations','reports'))
   or (event_object_schema='auth' and event_object_table='users')
order by event_object_schema,event_object_table,trigger_name;

-- 6) Auth-to-public profile consistency. Expected: zero rows after trigger has run.
select au.id, au.email
from auth.users au left join public.users pu on pu.id=au.id
where pu.id is null;

-- 7) Orphan profile rows. Expected: zero rows.
select pu.id, pu.email
from public.users pu left join auth.users au on au.id=pu.id
where au.id is null;

-- 8) Private storage bucket configuration.
select id,name,public,file_size_limit,allowed_mime_types
from storage.buckets where id='company-verification';

-- 9) Public-safe company directory view columns (must not include phone/email/address).
select column_name,data_type
from information_schema.columns
where table_schema='public' and table_name='public_company_directory'
order by ordinal_position;

-- 10) Count policies by table (review names and expressions in Dashboard if unexpected).
select schemaname, tablename, policyname, roles, cmd, qual, with_check
from pg_policies where schemaname='public'
order by tablename,policyname;


-- 11) Phase 2.2 authorization RPCs and their exposed execute privileges.
select routine_name, grantee, privilege_type
from information_schema.routine_privileges
where specific_schema='public'
  and routine_name in ('create_company_workspace','is_platform_admin','is_company_member','is_company_manager','nexvora_admin_overview')
order by routine_name,grantee,privilege_type;

-- 12) Phase 2.2 browser write privileges (review expected grants).
select table_name, privilege_type, column_name, grantee
from information_schema.column_privileges
where table_schema='public' and grantee='authenticated'
  and table_name in ('users','companies','company_members','products','buyer_requests','quotations','messages','notifications','verification_documents','verification_records','reports')
order by table_name,privilege_type,column_name;

-- 13) Confirm sensitive write grants are absent for normal authenticated clients.
select table_name, privilege_type
from information_schema.table_privileges
where table_schema='public' and grantee='authenticated'
  and table_name in ('company_members','messages','verification_documents','verification_records')
  and privilege_type in ('INSERT','UPDATE','DELETE')
order by table_name,privilege_type;
-- Expected: no rows for company_members/messages/verification_documents;
-- verification_records has scoped column UPDATE plus INSERT under admin-only RLS.

-- 14) Confirm private storage bucket and active policies.
select policyname,roles,cmd,qual,with_check
from pg_policies
where schemaname='storage' and tablename='objects'
  and policyname like 'verification_storage%'
order by policyname;

-- 15) Confirm view definition and the narrow public column list.
select pg_get_viewdef('public.public_company_directory'::regclass, true) as view_definition;
