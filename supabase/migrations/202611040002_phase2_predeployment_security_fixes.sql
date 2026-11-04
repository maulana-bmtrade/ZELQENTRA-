-- ZELQENTRA Phase 2 pre-deployment security corrections.
-- Apply after 202611040001_phase2_core.sql. Additive/idempotent; no data reset.
-- This migration is intentionally NOT executed against Supabase LIVE by the build process.

-- -----------------------------------------------------------------------------
-- 1. Storage policy cleanup and least-privilege rules.
--    Drop both legacy plural names reported from the prior environment and the
--    singular names introduced by Phase 2. Permissive policies are OR-combined.
-- -----------------------------------------------------------------------------
drop policy if exists conversation_attachments_read on storage.objects;
drop policy if exists conversation_attachments_insert on storage.objects;
drop policy if exists conversation_attachments_delete_own on storage.objects;
drop policy if exists conversation_attachment_read on storage.objects;
drop policy if exists conversation_attachment_insert on storage.objects;
drop policy if exists conversation_attachment_delete_own on storage.objects;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('conversation-attachments','conversation-attachments',false,10485760,
        array['application/pdf','image/jpeg','image/png'])
on conflict (id) do update set public=false,file_size_limit=10485760,
  allowed_mime_types=array['application/pdf','image/jpeg','image/png'];

-- Exactly two folder segments: <conversation UUID>/<authenticated uploader UUID>/<file>.
-- CASE protects UUID casts from malformed object paths.
create policy conversation_attachments_read on storage.objects
for select to authenticated
using (
  bucket_id='conversation-attachments'
  and array_length(storage.foldername(name),1)=2
  and (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
  and (storage.foldername(name))[2] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
  and exists (
    select 1 from public.conversations c
    where c.id=case when (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
                    then ((storage.foldername(name))[1])::uuid else null end
      and (public.is_company_member(c.buyer_company_id)
           or public.is_company_member(c.supplier_company_id))
  )
);

create policy conversation_attachments_insert on storage.objects
for insert to authenticated
with check (
  bucket_id='conversation-attachments'
  and array_length(storage.foldername(name),1)=2
  and (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
  and (storage.foldername(name))[2]=(select auth.uid())::text
  and exists (
    select 1 from public.conversations c
    where c.id=case when (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
                    then ((storage.foldername(name))[1])::uuid else null end
      and (public.is_company_member(c.buyer_company_id)
           or public.is_company_member(c.supplier_company_id))
  )
);

create policy conversation_attachments_delete_own on storage.objects
for delete to authenticated
using (
  bucket_id='conversation-attachments'
  and array_length(storage.foldername(name),1)=2
  and (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
  and (storage.foldername(name))[2]=(select auth.uid())::text
  and exists (
    select 1 from public.conversations c
    where c.id=case when (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
                    then ((storage.foldername(name))[1])::uuid else null end
      and (public.is_company_member(c.buyer_company_id)
           or public.is_company_member(c.supplier_company_id))
  )
);

-- Product catalogue images are intentionally public-readable, but only a manager
-- of the company named by the first path segment may upload/delete.
drop policy if exists product_image_read on storage.objects;
drop policy if exists product_image_insert on storage.objects;
drop policy if exists product_image_delete on storage.objects;
drop policy if exists product_images_read on storage.objects;
drop policy if exists product_images_insert on storage.objects;
drop policy if exists product_images_upload on storage.objects;
drop policy if exists product_images_delete on storage.objects;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('product-images','product-images',true,5242880,
        array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public=true,file_size_limit=5242880,
  allowed_mime_types=array['image/jpeg','image/png','image/webp'];
create policy product_image_read on storage.objects
for select to anon,authenticated using (bucket_id='product-images');
create policy product_image_insert on storage.objects
for insert to authenticated with check (
  bucket_id='product-images'
  and array_length(storage.foldername(name),1)=1
  and (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
  and public.is_company_manager(case when (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then ((storage.foldername(name))[1])::uuid else null end)
);
create policy product_image_delete on storage.objects
for delete to authenticated using (
  bucket_id='product-images'
  and array_length(storage.foldername(name),1)=1
  and (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
  and public.is_company_manager(case when (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then ((storage.foldername(name))[1])::uuid else null end)
);


-- Resolve pgcrypto functions from the extension's actual installed schema. On
-- Supabase this can be `extensions`; on a vanilla baseline it may be `public`.
create or replace function public.zq_invitation_token_hash(p_token text)
returns text language plpgsql security definer set search_path = '' as $$
declare v_schema text; v_hash bytea;
begin
  if p_token is null or length(p_token)<32 or length(p_token)>256 then
    raise exception 'invalid invitation token' using errcode='22023';
  end if;
  select n.nspname into v_schema
  from pg_catalog.pg_extension e
  join pg_catalog.pg_namespace n on n.oid=e.extnamespace
  where e.extname='pgcrypto';
  if v_schema is null then raise exception 'pgcrypto extension is not installed'; end if;
  execute format('select %I.digest(pg_catalog.convert_to($1,''UTF8''),''sha256'')',v_schema)
    into v_hash using p_token;
  return pg_catalog.encode(v_hash,'hex');
end; $$;
revoke all on function public.zq_invitation_token_hash(text) from public,anon,authenticated;

create or replace function public.create_company_invitation(
  p_company_id uuid,p_email text,p_role public.company_member_role default 'member'
) returns text language plpgsql security definer set search_path = '' as $$
declare v_token text; v_email text; v_actor_role public.company_member_role;
begin
  if auth.uid() is null or not public.is_company_manager(p_company_id) then
    raise exception 'forbidden' using errcode='42501';
  end if;
  v_email:=lower(trim(coalesce(p_email,'')));
  if v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then
    raise exception 'invalid email' using errcode='22023';
  end if;
  if p_role not in ('admin','member') then
    raise exception 'invalid invitation role' using errcode='22023';
  end if;
  select role into v_actor_role from public.company_members
    where company_id=p_company_id and user_id=auth.uid();
  if p_role='admin' and v_actor_role<>'owner' then
    raise exception 'only owner can invite an admin' using errcode='42501';
  end if;
  -- Two independent UUIDs provide a high-entropy one-time token without relying
  -- on an extension function's schema being present in search_path.
  v_token:=pg_catalog.replace(gen_random_uuid()::text,'-','') ||
           pg_catalog.replace(gen_random_uuid()::text,'-','');
  insert into public.company_invitations(company_id,invited_email,invited_role,token_hash,invited_by)
  values(p_company_id,v_email,p_role,public.zq_invitation_token_hash(v_token),auth.uid());
  return v_token;
end; $$;
revoke all on function public.create_company_invitation(uuid,text,public.company_member_role) from public,anon;
grant execute on function public.create_company_invitation(uuid,text,public.company_member_role) to authenticated;

create or replace function public.accept_company_invitation(p_token text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_inv public.company_invitations%rowtype; v_email text; v_uid uuid;
begin
  v_uid:=auth.uid();
  if v_uid is null then raise exception 'authentication required' using errcode='42501'; end if;
  v_email:=lower(coalesce(auth.jwt()->>'email',''));
  select * into v_inv from public.company_invitations
  where token_hash=public.zq_invitation_token_hash(p_token)
    and accepted_at is null and expires_at>now()
  for update;
  if not found then raise exception 'invitation invalid or expired' using errcode='22023'; end if;
  if v_inv.invited_email<>v_email then
    raise exception 'invitation email does not match signed-in account' using errcode='42501';
  end if;
  insert into public.company_members(company_id,user_id,role,invited_by)
  values(v_inv.company_id,v_uid,v_inv.invited_role,v_inv.invited_by)
  on conflict(company_id,user_id) do nothing;
  update public.company_invitations set accepted_at=now() where id=v_inv.id;
  return v_inv.company_id;
end; $$;
revoke all on function public.accept_company_invitation(text) from public,anon;
grant execute on function public.accept_company_invitation(text) to authenticated;

-- -----------------------------------------------------------------------------
-- 2. Remove forgeable custom-GUC authorization from quotation revision trigger.
--    The earlier app.quotation_revision GUC could be set by a PostgREST client.
--    A private transaction-scoped context table is writable only by its owner.
-- -----------------------------------------------------------------------------
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
create table if not exists private.quotation_revision_context (
  transaction_id bigint not null,
  backend_pid integer not null,
  quotation_id uuid not null,
  actor_id uuid not null,
  created_at timestamptz not null default now(),
  primary key (transaction_id,backend_pid,quotation_id)
);
revoke all on private.quotation_revision_context from public, anon, authenticated;

create or replace function public.guard_quotation_status_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_revision_authorized boolean := false;
  v_is_supplier boolean := false;
  v_is_buyer boolean := false;
begin
  select exists (
    select 1 from private.quotation_revision_context x
    where x.transaction_id=txid_current()
      and x.backend_pid=pg_backend_pid()
      and x.quotation_id=old.id
      and x.actor_id=auth.uid()
  ) into v_revision_authorized;

  if v_revision_authorized then
    if not public.is_company_manager(old.supplier_company_id)
       or old.status not in ('submitted','revised')
       or new.status<>'revised'
       or (to_jsonb(new) - 'unit_price' - 'currency' - 'quantity'
           - 'minimum_order_quantity' - 'lead_time_days' - 'validity_date'
           - 'notes' - 'status' - 'updated_at')
          <> (to_jsonb(old) - 'unit_price' - 'currency' - 'quantity'
           - 'minimum_order_quantity' - 'lead_time_days' - 'validity_date'
           - 'notes' - 'status' - 'updated_at') then
      raise exception 'not authorized to revise quotation terms' using errcode='42501';
    end if;
    return new;
  end if;

  -- Direct PostgREST updates may alter status only, never commercial fields.
  if (to_jsonb(new) - 'status' - 'updated_at')
     <> (to_jsonb(old) - 'status' - 'updated_at') then
    raise exception 'quotation commercial fields are immutable through direct client updates'
      using errcode='42501';
  end if;

  if public.is_platform_admin() then return new; end if;
  v_is_supplier := public.is_company_manager(old.supplier_company_id);
  select public.is_company_manager(b.buyer_company_id) into v_is_buyer
  from public.rfqs r join public.buyer_requests b on b.id=r.buyer_request_id
  where r.id=old.rfq_id;

  if v_is_supplier and old.status in ('submitted','revised')
     and new.status in ('revised','withdrawn') then return new; end if;
  if coalesce(v_is_buyer,false) and old.status in ('submitted','revised')
     and new.status in ('accepted','rejected') then return new; end if;
  raise exception 'not authorized for this quotation status transition' using errcode='42501';
end;
$$;

-- Ensure only the narrow status column is client-updatable. Revisions use RPC.
revoke update on public.quotations from anon, authenticated;
grant update(status) on public.quotations to authenticated;

-- Replace the RPC without a client-settable GUC. Context row is removed before
-- function return; a transaction failure rolls it back automatically.
drop function if exists public.revise_quotation(uuid,numeric,char(3),numeric,numeric,integer,date,text);
create or replace function public.revise_quotation(
  p_quotation_id uuid,
  p_unit_price numeric,
  p_currency char(3),
  p_quantity numeric,
  p_minimum_order_quantity numeric,
  p_lead_time_days integer,
  p_validity_date date,
  p_notes text
) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v public.quotations%rowtype;
begin
  if auth.uid() is null then raise exception 'authentication required' using errcode='42501'; end if;
  select * into v from public.quotations where id=p_quotation_id for update;
  if not found or not public.is_company_manager(v.supplier_company_id) then
    raise exception 'forbidden' using errcode='42501';
  end if;
  if v.status not in ('submitted','revised') then
    raise exception 'quotation cannot be revised in its current status';
  end if;
  if p_unit_price is null or p_unit_price<0 or p_quantity is null or p_quantity<=0
     or (p_minimum_order_quantity is not null and p_minimum_order_quantity<0)
     or (p_lead_time_days is not null and p_lead_time_days<0)
     or p_currency is null or p_currency !~ '^[A-Za-z]{3}$' then
    raise exception 'invalid quotation terms' using errcode='22023';
  end if;
  insert into private.quotation_revision_context(transaction_id,backend_pid,quotation_id,actor_id)
  values(txid_current(),pg_backend_pid(),p_quotation_id,auth.uid())
  on conflict (transaction_id,backend_pid,quotation_id)
  do update set actor_id=excluded.actor_id,created_at=now();

  update public.quotations
  set unit_price=p_unit_price,currency=upper(p_currency),quantity=p_quantity,
      minimum_order_quantity=p_minimum_order_quantity,lead_time_days=p_lead_time_days,
      validity_date=p_validity_date,notes=coalesce(p_notes,''),status='revised'
  where id=p_quotation_id;

  delete from private.quotation_revision_context
  where transaction_id=txid_current() and backend_pid=pg_backend_pid()
    and quotation_id=p_quotation_id and actor_id=auth.uid();
end;
$$;
revoke all on function public.revise_quotation(uuid,numeric,char(3),numeric,numeric,integer,date,text)
  from public,anon;
grant execute on function public.revise_quotation(uuid,numeric,char(3),numeric,numeric,integer,date,text)
  to authenticated;

-- Trigger-only SECURITY DEFINER routines must not be exposed as RPCs.
revoke all on function public.notify_new_message() from public,anon,authenticated;
revoke all on function public.notify_new_quotation() from public,anon,authenticated;
revoke all on function public.notify_quotation_status() from public,anon,authenticated;
revoke all on function public.notify_open_rfq() from public,anon,authenticated;
revoke all on function public.notify_product_moderation() from public,anon,authenticated;
revoke all on function public.notify_company_verification() from public,anon,authenticated;
revoke all on function public.log_quotation_status_history() from public,anon,authenticated;
revoke all on function public.log_new_quotation_status() from public,anon,authenticated;
revoke all on function public.notify_company_activity() from public,anon,authenticated;
revoke all on function public.notify_company_member_added() from public,anon,authenticated;
revoke all on function public.notify_new_rfq() from public,anon,authenticated;
revoke all on function public.guard_quotation_status_change() from public,anon,authenticated;
revoke all on function public.guard_buyer_request_update() from public,anon,authenticated;
revoke all on function public.require_product_re_review() from public,anon,authenticated;

-- -----------------------------------------------------------------------------
-- 3. Ensure one trigger instance per event. Notifications are best-effort so a
--    notification insert failure cannot roll back the business transaction.
-- -----------------------------------------------------------------------------
create or replace function public.notify_new_message()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_conversation public.conversations%rowtype; v_recipient uuid;
begin
  begin
    select * into v_conversation from public.conversations where id=new.conversation_id;
    if not found then return new; end if;
    for v_recipient in
      select distinct m.user_id from public.company_members m
      where m.user_id<>new.sender_id
        and m.company_id in (v_conversation.buyer_company_id,v_conversation.supplier_company_id)
    loop
      insert into public.notifications(user_id,type,title,body,data)
      values(v_recipient,'new_message','New business message','A participant sent a message.',
        jsonb_build_object('conversation_id',new.conversation_id,'message_id',new.id));
    end loop;
  exception when others then
    raise warning 'ZELQENTRA notification failure (new_message): %', SQLERRM;
  end;
  return new;
end; $$;

create or replace function public.notify_new_quotation()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_buyer_company uuid; v_user uuid;
begin
  begin
    select b.buyer_company_id into v_buyer_company
    from public.rfqs r join public.buyer_requests b on b.id=r.buyer_request_id
    where r.id=new.rfq_id;
    if v_buyer_company is not null then
      for v_user in select user_id from public.company_members where company_id=v_buyer_company loop
        insert into public.notifications(user_id,type,title,body,data)
        values(v_user,'quotation_received','New quotation received',
          'A supplier submitted a quotation for your RFQ.',
          jsonb_build_object('quotation_id',new.id,'rfq_id',new.rfq_id));
      end loop;
    end if;
  exception when others then
    raise warning 'ZELQENTRA notification failure (quotation_received): %', SQLERRM;
  end;
  return new;
end; $$;

create or replace function public.notify_quotation_status()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_company uuid; v_user uuid;
begin
  if new.status is not distinct from old.status then return new; end if;
  begin
    if new.status in ('accepted','rejected') then
      v_company:=new.supplier_company_id;
    else
      select b.buyer_company_id into v_company
      from public.rfqs r join public.buyer_requests b on b.id=r.buyer_request_id
      where r.id=new.rfq_id;
    end if;
    for v_user in select user_id from public.company_members where company_id=v_company loop
      insert into public.notifications(user_id,type,title,body,data)
      values(v_user,'quotation_status_changed','Quotation status updated',
        'A quotation status has changed.',jsonb_build_object('quotation_id',new.id,'status',new.status));
    end loop;
  exception when others then
    raise warning 'ZELQENTRA notification failure (quotation_status): %', SQLERRM;
  end;
  return new;
end; $$;

create or replace function public.notify_new_rfq()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_buyer_company uuid; v_user uuid;
begin
  begin
    select buyer_company_id into v_buyer_company
    from public.buyer_requests where id=new.buyer_request_id;
    if v_buyer_company is not null then
      for v_user in
        select distinct m.user_id from public.company_members m
        join public.users u on u.id=m.user_id
        where u.role='supplier' and m.company_id<>v_buyer_company
      loop
        insert into public.notifications(user_id,type,title,body,data)
        values(v_user,'rfq_opened','New buyer request',
          'A buyer request is now open for supplier responses.',
          jsonb_build_object('buyer_request_id',new.buyer_request_id,'rfq_id',new.id));
      end loop;
    end if;
  exception when others then
    raise warning 'ZELQENTRA notification failure (rfq_opened): %', SQLERRM;
  end;
  return new;
end; $$;

create or replace function public.notify_product_moderation()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_user uuid;
begin
  if new.status is distinct from old.status and new.status in ('published','rejected') then
    begin
      for v_user in select user_id from public.company_members where company_id=new.company_id loop
        insert into public.notifications(user_id,type,title,body,data)
        values(v_user,'product_moderation','Product review updated',
          'A product listing review status has changed.',
          jsonb_build_object('product_id',new.id,'status',new.status));
      end loop;
    exception when others then
      raise warning 'ZELQENTRA notification failure (product_moderation): %', SQLERRM;
    end;
  end if;
  return new;
end; $$;

create or replace function public.notify_company_verification()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_user uuid;
begin
  if new.verification_status is distinct from old.verification_status then
    begin
      for v_user in select user_id from public.company_members where company_id=new.id loop
        insert into public.notifications(user_id,type,title,body,data)
        values(v_user,'company_verification','Company verification updated',
          'Your company verification status has changed.',
          jsonb_build_object('company_id',new.id,'status',new.verification_status));
      end loop;
    exception when others then
      raise warning 'ZELQENTRA notification failure (company_verification): %', SQLERRM;
    end;
  end if;
  return new;
end; $$;

create or replace function public.notify_company_activity()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_user uuid;
begin
  begin
    for v_user in select user_id from public.company_members
      where company_id=new.id and user_id<>auth.uid()
    loop
      insert into public.notifications(user_id,type,title,body,data)
      values(v_user,'company_activity','Company profile updated',
        'A company administrator updated the company profile.',jsonb_build_object('company_id',new.id));
    end loop;
  exception when others then
    raise warning 'ZELQENTRA notification failure (company_activity): %', SQLERRM;
  end;
  return new;
end; $$;

create or replace function public.notify_company_member_added()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_user uuid; v_company_name text;
begin
  begin
    select display_name into v_company_name from public.companies where id=new.company_id;
    for v_user in select user_id from public.company_members
      where company_id=new.company_id and user_id<>new.user_id
    loop
      insert into public.notifications(user_id,type,title,body,data)
      values(v_user,'company_activity','New company member',
        coalesce(v_company_name,'Your company')||' has a new member.',
        jsonb_build_object('company_id',new.company_id,'user_id',new.user_id));
    end loop;
  exception when others then
    raise warning 'ZELQENTRA notification failure (company_member_added): %', SQLERRM;
  end;
  return new;
end; $$;

-- Re-apply trigger-only function ACLs after CREATE OR REPLACE (ACLs are preserved,
-- but explicit revocation documents and enforces the intended RPC boundary).
revoke all on function public.notify_new_message() from public,anon,authenticated;
revoke all on function public.notify_new_quotation() from public,anon,authenticated;
revoke all on function public.notify_quotation_status() from public,anon,authenticated;
revoke all on function public.notify_new_rfq() from public,anon,authenticated;
revoke all on function public.notify_product_moderation() from public,anon,authenticated;
revoke all on function public.notify_company_verification() from public,anon,authenticated;
revoke all on function public.notify_company_activity() from public,anon,authenticated;
revoke all on function public.notify_company_member_added() from public,anon,authenticated;

-- Ensure exactly one trigger is installed for each event.
drop trigger if exists trg_notify_new_message on public.messages;
create trigger trg_notify_new_message after insert on public.messages
for each row execute function public.notify_new_message();
drop trigger if exists trg_notify_new_quotation on public.quotations;
create trigger trg_notify_new_quotation after insert on public.quotations
for each row execute function public.notify_new_quotation();
drop trigger if exists trg_notify_quotation_status on public.quotations;
create trigger trg_notify_quotation_status after update of status on public.quotations
for each row execute function public.notify_quotation_status();
drop trigger if exists trg_notify_new_rfq on public.rfqs;
create trigger trg_notify_new_rfq after insert on public.rfqs
for each row execute function public.notify_new_rfq();
drop trigger if exists trg_notify_product_moderation on public.products;
create trigger trg_notify_product_moderation after update of status on public.products
for each row execute function public.notify_product_moderation();
drop trigger if exists trg_notify_company_verification on public.companies;
create trigger trg_notify_company_verification after update of verification_status on public.companies
for each row execute function public.notify_company_verification();
drop trigger if exists trg_notify_company_activity on public.companies;
create trigger trg_notify_company_activity after update of legal_name,display_name,description,website_url,
 country_code,city,address,industry,company_type,contact_email,phone,logo_path on public.companies
for each row execute function public.notify_company_activity();
drop trigger if exists trg_notify_company_member_added on public.company_members;
create trigger trg_notify_company_member_added after insert on public.company_members
for each row execute function public.notify_company_member_added();

-- Restore private function ACLs after replacements.
revoke all on function public.guard_quotation_status_change() from public,anon,authenticated;
revoke all on function public.notify_new_message() from public,anon,authenticated;
revoke all on function public.notify_new_quotation() from public,anon,authenticated;
revoke all on function public.notify_quotation_status() from public,anon,authenticated;
revoke all on function public.notify_new_rfq() from public,anon,authenticated;
revoke all on function public.notify_product_moderation() from public,anon,authenticated;
revoke all on function public.notify_company_verification() from public,anon,authenticated;
revoke all on function public.notify_company_activity() from public,anon,authenticated;
revoke all on function public.notify_company_member_added() from public,anon,authenticated;

-- -----------------------------------------------------------------------------
-- 4. Prevent destructive bypasses and self-moderation.
-- -----------------------------------------------------------------------------
-- RFQs are created atomically by publish_buyer_request_with_rfq or
-- open_existing_buyer_request. Client-side mutation could re-parent an RFQ or
-- cascade-delete supplier quotations, so no direct client DML is required.
revoke insert, update, delete on public.rfqs from anon, authenticated;
-- Buyer requests may be edited/closed through the constrained update path, but
-- must not be deleted because their RFQ/quotation descendants cascade.
revoke delete on public.buyer_requests from anon, authenticated;

create or replace function public.moderate_product(
  p_product_id uuid,p_status public.product_status
) returns void language plpgsql security definer set search_path = '' as $$
declare v_company uuid;
begin
  if not public.is_platform_admin() then raise exception 'forbidden' using errcode='42501'; end if;
  select company_id into v_company from public.products where id=p_product_id;
  if v_company is null then raise exception 'product not found' using errcode='P0002'; end if;
  if exists(select 1 from public.company_members
            where company_id=v_company and user_id=auth.uid()) then
    raise exception 'platform moderator cannot moderate a product belonging to their own company'
      using errcode='42501';
  end if;
  if p_status not in ('published','rejected','archived') then
    raise exception 'invalid moderation status' using errcode='22023';
  end if;
  update public.products set status=p_status where id=p_product_id;
end; $$;
revoke all on function public.moderate_product(uuid,public.product_status) from public,anon;
grant execute on function public.moderate_product(uuid,public.product_status) to authenticated;

create or replace function public.moderate_company_verification(
  p_company_id uuid,p_status public.verification_status,p_notes text default ''
) returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_platform_admin() then raise exception 'forbidden' using errcode='42501'; end if;
  if exists(select 1 from public.company_members
            where company_id=p_company_id and user_id=auth.uid()) then
    raise exception 'platform moderator cannot verify their own company' using errcode='42501';
  end if;
  if not exists(select 1 from public.companies where id=p_company_id) then
    raise exception 'company not found' using errcode='P0002';
  end if;
  if p_notes is not null and length(p_notes)>4000 then
    raise exception 'review notes are too long' using errcode='22023';
  end if;
  update public.companies set verification_status=p_status where id=p_company_id;
  insert into public.verification_records(company_id,reviewed_by,status,review_notes,reviewed_at)
  values(p_company_id,auth.uid(),p_status,coalesce(p_notes,''),now());
end; $$;
revoke all on function public.moderate_company_verification(uuid,public.verification_status,text) from public,anon;
grant execute on function public.moderate_company_verification(uuid,public.verification_status,text) to authenticated;


-- Auth bootstrap is trigger-only; it is not a public RPC surface.
revoke all on function public.handle_new_user() from public,anon,authenticated;
