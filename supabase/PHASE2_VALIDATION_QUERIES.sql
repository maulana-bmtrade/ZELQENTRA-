-- ZELQENTRA Phase 2 read-only pre/post-deployment validation.
-- Run only after manually applying migrations 001-003, 040001 and 040002.
-- These queries do not mutate data or schema.

-- A. Required objects, enum types and added columns.
select to_regclass('public.company_invitations') as company_invitations,
       to_regclass('public.quotation_status_history') as quotation_status_history,
       to_regclass('private.quotation_revision_context') as private_revision_context;
select table_name,column_name,data_type,udt_name
from information_schema.columns
where table_schema='public' and (
  (table_name='quotations' and column_name='minimum_order_quantity') or
  (table_name='company_invitations' and column_name in ('company_id','invited_email','invited_role','token_hash','invited_by','expires_at','accepted_at'))
) order by table_name,ordinal_position;
select n.nspname as schema_name,t.typname as enum_name,e.enumlabel,e.enumsortorder
from pg_type t join pg_namespace n on n.oid=t.typnamespace
join pg_enum e on e.enumtypid=t.oid
where n.nspname='public' and t.typname in ('company_member_role','product_status','rfq_status','quotation_status','verification_status')
order by t.typname,e.enumsortorder;

-- B. RPC identities and SECURITY DEFINER configuration.
select n.nspname,p.proname,pg_get_function_identity_arguments(p.oid) as arguments,
       p.prosecdef as security_definer,
       coalesce(array_to_string(p.proconfig,','),'(default)') as function_config,
       has_function_privilege('anon',p.oid,'EXECUTE') as anon_can_execute,
       has_function_privilege('authenticated',p.oid,'EXECUTE') as authenticated_can_execute
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname in ('public','private')
  and p.proname in (
    'create_company_workspace','create_company_invitation','accept_company_invitation',
    'update_company_member_role','remove_company_member','publish_buyer_request_with_rfq',
    'open_existing_buyer_request','revise_quotation','moderate_product',
    'moderate_company_verification','nexvora_admin_overview','guard_quotation_status_change'
  ) order by n.nspname,p.proname;

-- C. All policies on storage.objects. Inspect every row, not only policies whose
--    text happens to mention the bucket. Any broad policy may be OR-combined.
select policyname,cmd,roles,qual,with_check
from pg_policies where schemaname='storage' and tablename='objects'
order by policyname;

-- D. Required bucket privacy and MIME/size restrictions.
select id,name,public,file_size_limit,allowed_mime_types
from storage.buckets
where id in ('conversation-attachments','product-images','company-verification')
order by id;

-- E. Check that legacy attachment policy names are absent.
select policyname,cmd,roles,qual,with_check
from pg_policies
where schemaname='storage' and tablename='objects'
  and policyname in (
    'conversation_attachments_read','conversation_attachments_insert',
    'conversation_attachments_delete_own','conversation_attachment_read',
    'conversation_attachment_insert','conversation_attachment_delete_own'
  );
-- Expected: zero rows. Also manually inspect query C for unknown broad policies.

-- F. RLS and grants for business-critical tables.
select schemaname,tablename,rowsecurity,forcerowsecurity
from pg_tables
where schemaname='public' and tablename in (
 'companies','company_members','products','buyer_requests','rfqs','quotations',
 'conversations','messages','notifications','company_invitations','quotation_status_history'
) order by tablename;
select table_schema,table_name,grantee,privilege_type
from information_schema.role_table_grants
where table_schema in ('public','private')
  and table_name in ('quotations','rfqs','buyer_requests','company_members','quotation_revision_context')
order by table_schema,table_name,grantee,privilege_type;

-- G. Triggers: there should be one instance for each named event trigger.
select event_object_schema,event_object_table,trigger_name,event_manipulation,action_timing
from information_schema.triggers
where event_object_schema='public'
  and (trigger_name ilike '%notify%' or trigger_name ilike '%quotation%' or trigger_name ilike '%buyer_request%')
order by event_object_table,trigger_name,event_manipulation;

-- H. Foreign-key paths used by RFQ/quotation and attachment authorization.
select tc.table_name,kcu.column_name,ccu.table_name as foreign_table_name,ccu.column_name as foreign_column_name,rc.delete_rule
from information_schema.table_constraints tc
join information_schema.key_column_usage kcu
  on tc.constraint_name=kcu.constraint_name and tc.constraint_schema=kcu.constraint_schema
join information_schema.constraint_column_usage ccu
  on ccu.constraint_name=tc.constraint_name and ccu.constraint_schema=tc.constraint_schema
join information_schema.referential_constraints rc
  on rc.constraint_name=tc.constraint_name and rc.constraint_schema=tc.constraint_schema
where tc.constraint_type='FOREIGN KEY' and tc.constraint_schema='public'
  and tc.table_name in ('rfqs','quotations','conversations','messages','company_invitations','quotation_status_history')
order by tc.table_name,kcu.column_name;

-- I. Trigger-function grants: trigger-only routines should not be callable as RPC.
select p.proname,has_function_privilege('anon',p.oid,'EXECUTE') as anon_can_execute,
       has_function_privilege('authenticated',p.oid,'EXECUTE') as authenticated_can_execute
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.prorettype='trigger'::regtype
order by p.proname;
