-- ZELQENTRA Phase 2 core extensions. REVIEW and apply manually; never auto-run from browser.
-- Existing tables, RLS and roles are preserved. This migration is additive.

-- Company invitations: invitation token is delivered out-of-band by the workspace owner/admin.
create table if not exists public.company_invitations (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  invited_email text not null,
  invited_role public.company_member_role not null default 'member',
  token_hash text not null unique,
  invited_by uuid not null references public.users(id),
  expires_at timestamptz not null default (now() + interval '7 days'),
  accepted_at timestamptz,
  created_at timestamptz not null default now(),
  constraint company_invitation_role check (invited_role in ('admin','member'))
);
alter table public.company_invitations enable row level security;
drop policy if exists company_invitation_manager_read on public.company_invitations;
create policy company_invitation_manager_read on public.company_invitations for select to authenticated
using (public.is_company_manager(company_id));
revoke all on public.company_invitations from anon, authenticated;
grant select on public.company_invitations to authenticated;

create or replace function public.create_company_invitation(p_company_id uuid,p_email text,p_role public.company_member_role default 'member')
returns text language plpgsql security definer set search_path = '' as $$
declare v_token text; v_email text;
begin
  if auth.uid() is null or not public.is_company_manager(p_company_id) then raise exception 'forbidden' using errcode='42501'; end if;
  v_email := lower(trim(p_email));
  if v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then raise exception 'invalid email'; end if;
  if p_role not in ('admin','member') then raise exception 'invalid invitation role'; end if;
  v_token := encode(public.gen_random_bytes(32),'hex');
  insert into public.company_invitations(company_id,invited_email,invited_role,token_hash,invited_by)
  values(p_company_id,v_email,p_role,encode(public.digest(v_token,'sha256'),'hex'),auth.uid());
  return v_token;
end; $$;
revoke all on function public.create_company_invitation(uuid,text,public.company_member_role) from public,anon;
grant execute on function public.create_company_invitation(uuid,text,public.company_member_role) to authenticated;

create or replace function public.accept_company_invitation(p_token text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_inv public.company_invitations%rowtype; v_email text; v_uid uuid;
begin
  v_uid := auth.uid();
  if v_uid is null then raise exception 'authentication required' using errcode='42501'; end if;
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  select * into v_inv from public.company_invitations
   where token_hash=encode(public.digest(p_token,'sha256'),'hex') and accepted_at is null and expires_at>now()
   for update;
  if not found then raise exception 'invitation invalid or expired'; end if;
  if v_inv.invited_email <> v_email then raise exception 'invitation email does not match signed-in account' using errcode='42501'; end if;
  insert into public.company_members(company_id,user_id,role,invited_by)
  values(v_inv.company_id,v_uid,v_inv.invited_role,v_inv.invited_by)
  on conflict(company_id,user_id) do nothing;
  update public.company_invitations set accepted_at=now() where id=v_inv.id;
  return v_inv.company_id;
end; $$;
revoke all on function public.accept_company_invitation(text) from public,anon;
grant execute on function public.accept_company_invitation(text) to authenticated;

-- Private conversation attachments. Path format: <conversation_uuid>/<uploader_uuid>/<filename>.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('conversation-attachments','conversation-attachments',false,10485760,array['application/pdf','image/jpeg','image/png'])
on conflict(id) do update set public=false,file_size_limit=10485760,allowed_mime_types=array['application/pdf','image/jpeg','image/png'];
-- Remove legacy pluralized and prior singular policy names as well. PostgreSQL permissive
-- policies are OR-combined, so leaving any broader legacy policy would bypass these rules.
drop policy if exists conversation_attachments_read on storage.objects;
drop policy if exists conversation_attachments_insert on storage.objects;
drop policy if exists conversation_attachments_delete_own on storage.objects;
drop policy if exists conversation_attachment_read on storage.objects;
create policy conversation_attachment_read on storage.objects for select to authenticated
using(bucket_id='conversation-attachments' and exists(
 select 1 from public.conversations c where c.id=((storage.foldername(name))[1])::uuid
 and (public.is_company_member(c.buyer_company_id) or public.is_company_member(c.supplier_company_id))
));
drop policy if exists conversation_attachment_insert on storage.objects;
create policy conversation_attachment_insert on storage.objects for insert to authenticated
with check(bucket_id='conversation-attachments'
 and (storage.foldername(name))[2]=(select auth.uid())::text
 and exists(select 1 from public.conversations c where c.id=((storage.foldername(name))[1])::uuid
 and (public.is_company_member(c.buyer_company_id) or public.is_company_member(c.supplier_company_id))));
drop policy if exists conversation_attachment_delete_own on storage.objects;
create policy conversation_attachment_delete_own on storage.objects for delete to authenticated
using(bucket_id='conversation-attachments' and (storage.foldername(name))[2]=(select auth.uid())::text
 and exists(select 1 from public.conversations c where c.id=((storage.foldername(name))[1])::uuid
 and (public.is_company_member(c.buyer_company_id) or public.is_company_member(c.supplier_company_id))));

-- Product images are intentionally public catalogue assets; private conversation files remain private.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('product-images','product-images',true,5242880,array['image/jpeg','image/png','image/webp'])
on conflict(id) do update set public=true,file_size_limit=5242880,allowed_mime_types=array['image/jpeg','image/png','image/webp'];
drop policy if exists product_image_read on storage.objects;
create policy product_image_read on storage.objects for select to anon,authenticated using(bucket_id='product-images');
drop policy if exists product_image_insert on storage.objects;
create policy product_image_insert on storage.objects for insert to authenticated with check(
 bucket_id='product-images' and (storage.foldername(name))[1] is not null
 and public.is_company_manager(((storage.foldername(name))[1])::uuid));
drop policy if exists product_image_delete on storage.objects;
create policy product_image_delete on storage.objects for delete to authenticated using(
 bucket_id='product-images' and (storage.foldername(name))[1] is not null
 and public.is_company_manager(((storage.foldername(name))[1])::uuid));

-- Event-driven notifications. Triggers write only recipient-scoped notification rows.
create or replace function public.notify_new_message()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_conversation public.conversations%rowtype; v_recipient uuid;
begin
 select * into v_conversation from public.conversations where id=new.conversation_id;
 for v_recipient in
  select distinct m.user_id from public.company_members m
  where m.user_id <> new.sender_id and m.company_id in (v_conversation.buyer_company_id,v_conversation.supplier_company_id)
 loop
  insert into public.notifications(user_id,type,title,body,data)
  values(v_recipient,'new_message','New business message','A participant sent a message.',jsonb_build_object('conversation_id',new.conversation_id,'message_id',new.id));
 end loop;
 return new;
end; $$;
drop trigger if exists trg_notify_new_message on public.messages;
create trigger trg_notify_new_message after insert on public.messages for each row execute function public.notify_new_message();

create or replace function public.notify_new_quotation()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_buyer_company uuid; v_user uuid;
begin
 select b.buyer_company_id into v_buyer_company from public.rfqs r join public.buyer_requests b on b.id=r.buyer_request_id where r.id=new.rfq_id;
 for v_user in select user_id from public.company_members where company_id=v_buyer_company loop
  insert into public.notifications(user_id,type,title,body,data)
  values(v_user,'quotation_received','New quotation received','A supplier submitted a quotation for your RFQ.',jsonb_build_object('quotation_id',new.id,'rfq_id',new.rfq_id));
 end loop;
 return new;
end; $$;
drop trigger if exists trg_notify_new_quotation on public.quotations;
create trigger trg_notify_new_quotation after insert on public.quotations for each row execute function public.notify_new_quotation();

create or replace function public.notify_quotation_status()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_company uuid; v_user uuid;
begin
 if new.status is not distinct from old.status then return new; end if;
 if new.status in ('accepted','rejected') then
  v_company:=new.supplier_company_id;
 else
  select b.buyer_company_id into v_company from public.rfqs r join public.buyer_requests b on b.id=r.buyer_request_id where r.id=new.rfq_id;
 end if;
 for v_user in select user_id from public.company_members where company_id=v_company loop
  insert into public.notifications(user_id,type,title,body,data)
  values(v_user,'quotation_status_changed','Quotation status updated','A quotation status has changed.',jsonb_build_object('quotation_id',new.id,'status',new.status));
 end loop;
 return new;
end; $$;
drop trigger if exists trg_notify_quotation_status on public.quotations;
create trigger trg_notify_quotation_status after update of status on public.quotations for each row execute function public.notify_quotation_status();

create or replace function public.notify_open_rfq()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_user uuid; v_rfq uuid;
begin
 if new.status='open' and (tg_op='INSERT' or old.status is distinct from 'open') then
  select id into v_rfq from public.rfqs where buyer_request_id=new.id;
  for v_user in select distinct m.user_id from public.company_members m join public.users u on u.id=m.user_id where u.role='supplier' and m.company_id<>new.buyer_company_id loop
   insert into public.notifications(user_id,type,title,body,data)
   values(v_user,'rfq_opened','New buyer request','A buyer request is now open for supplier responses.',jsonb_build_object('buyer_request_id',new.id,'rfq_id',v_rfq));
  end loop;
 end if;
 return new;
end; $$;
drop trigger if exists trg_notify_open_rfq_insert on public.buyer_requests;
create trigger trg_notify_open_rfq_insert after insert on public.buyer_requests for each row execute function public.notify_open_rfq();
drop trigger if exists trg_notify_open_rfq_update on public.buyer_requests;
create trigger trg_notify_open_rfq_update after update of status on public.buyer_requests for each row execute function public.notify_open_rfq();

-- No read receipt writes are granted for messages in the existing hardening migration.
-- No product status update is granted to company users: publication remains a trusted moderation action.

create or replace function public.update_company_member_role(p_member_id uuid,p_role public.company_member_role)
returns void language plpgsql security definer set search_path = '' as $$
declare v_company uuid; v_target_role public.company_member_role; v_actor_role public.company_member_role;
begin
 select company_id,role into v_company,v_target_role from public.company_members where id=p_member_id;
 if v_company is null or not public.is_company_manager(v_company) then raise exception 'forbidden' using errcode='42501'; end if;
 select role into v_actor_role from public.company_members where company_id=v_company and user_id=auth.uid();
 if v_target_role='owner' or p_role='owner' then raise exception 'owner role cannot be reassigned through this operation'; end if;
 if v_actor_role<>'owner' and (v_target_role='admin' or p_role='admin') then raise exception 'only owner can manage admin role' using errcode='42501'; end if;
 update public.company_members set role=p_role where id=p_member_id;
end; $$;
revoke all on function public.update_company_member_role(uuid,public.company_member_role) from public,anon;
grant execute on function public.update_company_member_role(uuid,public.company_member_role) to authenticated;

create or replace function public.remove_company_member(p_member_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare v_company uuid; v_target_role public.company_member_role; v_actor_role public.company_member_role;
begin
 select company_id,role into v_company,v_target_role from public.company_members where id=p_member_id;
 if v_company is null or not public.is_company_manager(v_company) then raise exception 'forbidden' using errcode='42501'; end if;
 select role into v_actor_role from public.company_members where company_id=v_company and user_id=auth.uid();
 if v_target_role='owner' then raise exception 'owner cannot be removed'; end if;
 if v_target_role='admin' and v_actor_role<>'owner' then raise exception 'only owner can remove admin' using errcode='42501'; end if;
 delete from public.company_members where id=p_member_id;
end; $$;
revoke all on function public.remove_company_member(uuid) from public,anon;
grant execute on function public.remove_company_member(uuid) to authenticated;

-- Trusted moderation RPCs; company managers cannot publish their own products or self-verify.
create or replace function public.moderate_product(p_product_id uuid,p_status public.product_status)
returns void language plpgsql security definer set search_path = '' as $$
begin
 if not public.is_platform_admin() then raise exception 'forbidden' using errcode='42501'; end if;
 if p_status not in ('published','rejected','archived') then raise exception 'invalid moderation status'; end if;
 update public.products set status=p_status where id=p_product_id;
end; $$;
revoke all on function public.moderate_product(uuid,public.product_status) from public,anon;
grant execute on function public.moderate_product(uuid,public.product_status) to authenticated;

create or replace function public.moderate_company_verification(p_company_id uuid,p_status public.verification_status,p_notes text default '')
returns void language plpgsql security definer set search_path = '' as $$
begin
 if not public.is_platform_admin() then raise exception 'forbidden' using errcode='42501'; end if;
 update public.companies set verification_status=p_status where id=p_company_id;
 insert into public.verification_records(company_id,reviewed_by,status,review_notes,reviewed_at)
 values(p_company_id,auth.uid(),p_status,coalesce(p_notes,''),now());
end; $$;
revoke all on function public.moderate_company_verification(uuid,public.verification_status,text) from public,anon;
grant execute on function public.moderate_company_verification(uuid,public.verification_status,text) to authenticated;

create or replace function public.notify_product_moderation()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_user uuid;
begin
 if new.status is distinct from old.status and new.status in ('published','rejected') then
  for v_user in select user_id from public.company_members where company_id=new.company_id loop
   insert into public.notifications(user_id,type,title,body,data)
   values(v_user,'product_moderation','Product review updated','A product listing review status has changed.',jsonb_build_object('product_id',new.id,'status',new.status));
  end loop;
 end if;
 return new;
end; $$;
drop trigger if exists trg_notify_product_moderation on public.products;
create trigger trg_notify_product_moderation after update of status on public.products for each row execute function public.notify_product_moderation();

create or replace function public.notify_company_verification()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_user uuid;
begin
 if new.verification_status is distinct from old.verification_status then
  for v_user in select user_id from public.company_members where company_id=new.id loop
   insert into public.notifications(user_id,type,title,body,data)
   values(v_user,'company_verification','Company verification updated','Your company verification status has changed.',jsonb_build_object('company_id',new.id,'status',new.verification_status));
  end loop;
 end if;
 return new;
end; $$;
drop trigger if exists trg_notify_company_verification on public.companies;
create trigger trg_notify_company_verification after update of verification_status on public.companies for each row execute function public.notify_company_verification();

create table if not exists public.quotation_status_history (
 id uuid primary key default gen_random_uuid(),
 quotation_id uuid not null references public.quotations(id) on delete cascade,
 old_status public.quotation_status,
 new_status public.quotation_status not null,
 changed_by uuid references public.users(id),
 changed_at timestamptz not null default now()
);
alter table public.quotation_status_history enable row level security;
drop policy if exists quotation_history_parties_read on public.quotation_status_history;
create policy quotation_history_parties_read on public.quotation_status_history for select to authenticated using (
 exists(select 1 from public.quotations q where q.id=quotation_id and
 (public.is_company_member(q.supplier_company_id) or exists(select 1 from public.rfqs r join public.buyer_requests b on b.id=r.buyer_request_id where r.id=q.rfq_id and public.is_company_member(b.buyer_company_id))))
);
revoke all on public.quotation_status_history from anon,authenticated;
grant select on public.quotation_status_history to authenticated;
create or replace function public.log_quotation_status_history()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
 if new.status is distinct from old.status then
  insert into public.quotation_status_history(quotation_id,old_status,new_status,changed_by)
  values(new.id,old.status,new.status,auth.uid());
 end if;
 return new;
end; $$;
drop trigger if exists trg_log_quotation_status_history on public.quotations;
create trigger trg_log_quotation_status_history after update of status on public.quotations for each row execute function public.log_quotation_status_history();

create or replace function public.revise_quotation(p_quotation_id uuid,p_unit_price numeric,p_currency char(3),p_quantity numeric,p_lead_time_days integer,p_validity_date date,p_notes text)
returns void language plpgsql security definer set search_path = '' as $$
declare v public.quotations%rowtype;
begin
 select * into v from public.quotations where id=p_quotation_id for update;
 if not found or not public.is_company_manager(v.supplier_company_id) then raise exception 'forbidden' using errcode='42501'; end if;
 if v.status not in ('submitted','revised') then raise exception 'quotation cannot be revised in its current status'; end if;
 if p_unit_price<0 or p_quantity<=0 or p_lead_time_days<0 then raise exception 'invalid quotation terms'; end if;
 update public.quotations set unit_price=p_unit_price,currency=upper(p_currency),quantity=p_quantity,lead_time_days=p_lead_time_days,validity_date=p_validity_date,notes=coalesce(p_notes,''),status='revised' where id=p_quotation_id;
end; $$;
revoke all on function public.revise_quotation(uuid,numeric,char(3),numeric,integer,date,text) from public,anon;
grant execute on function public.revise_quotation(uuid,numeric,char(3),numeric,integer,date,text) to authenticated;

create or replace function public.guard_quotation_status_change()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_is_supplier boolean; v_is_buyer boolean;
begin
 if (to_jsonb(new) - 'status' - 'updated_at') <> (to_jsonb(old) - 'status' - 'updated_at') then
  raise exception 'quotation commercial fields are immutable through direct client updates' using errcode='42501';
 end if;
 if public.is_platform_admin() then return new; end if;
 v_is_supplier := public.is_company_manager(old.supplier_company_id);
 select public.is_company_manager(b.buyer_company_id) into v_is_buyer
 from public.rfqs r join public.buyer_requests b on b.id=r.buyer_request_id where r.id=old.rfq_id;
 if v_is_supplier and old.status in ('submitted','revised') and new.status in ('revised','withdrawn') then return new; end if;
 if coalesce(v_is_buyer,false) and old.status in ('submitted','revised') and new.status in ('accepted','rejected') then return new; end if;
 raise exception 'not authorized for this quotation status transition' using errcode='42501';
end; $$;

create or replace function public.revise_quotation(p_quotation_id uuid,p_unit_price numeric,p_currency char(3),p_quantity numeric,p_lead_time_days integer,p_validity_date date,p_notes text)
returns void language plpgsql security definer set search_path = '' as $$
declare v public.quotations%rowtype;
begin
 select * into v from public.quotations where id=p_quotation_id for update;
 if not found or not public.is_company_manager(v.supplier_company_id) then raise exception 'forbidden' using errcode='42501'; end if;
 if v.status not in ('submitted','revised') then raise exception 'quotation cannot be revised in its current status'; end if;
 if p_unit_price<0 or p_quantity<=0 or (p_lead_time_days is not null and p_lead_time_days<0) then raise exception 'invalid quotation terms'; end if;
 update public.quotations set unit_price=p_unit_price,currency=upper(p_currency),quantity=p_quantity,lead_time_days=p_lead_time_days,validity_date=p_validity_date,notes=coalesce(p_notes,''),status='revised' where id=p_quotation_id;
end; $$;

create or replace function public.log_new_quotation_status()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
 insert into public.quotation_status_history(quotation_id,old_status,new_status,changed_by)
 values(new.id,null,new.status,new.submitted_by);
 return new;
end; $$;
drop trigger if exists trg_log_new_quotation_status on public.quotations;
create trigger trg_log_new_quotation_status after insert on public.quotations for each row execute function public.log_new_quotation_status();

create or replace function public.notify_open_rfq()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_user uuid; v_rfq uuid; v_should_notify boolean;
begin
 if tg_op='INSERT' then
  v_should_notify := new.status='open';
 else
  v_should_notify := new.status='open' and old.status is distinct from 'open';
 end if;
 if v_should_notify then
  select id into v_rfq from public.rfqs where buyer_request_id=new.id;
  for v_user in select distinct m.user_id from public.company_members m join public.users u on u.id=m.user_id where u.role='supplier' and m.company_id<>new.buyer_company_id loop
   insert into public.notifications(user_id,type,title,body,data)
   values(v_user,'rfq_opened','New buyer request','A buyer request is now open for supplier responses.',jsonb_build_object('buyer_request_id',new.id,'rfq_id',v_rfq));
  end loop;
 end if;
 return new;
end; $$;

-- Company managers may edit a request while it is draft/open only and before supplier quotations exist.
create or replace function public.guard_buyer_request_update()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_has_quotes boolean; v_has_content_changes boolean;
begin
 v_has_content_changes := (to_jsonb(new) - 'status' - 'updated_at') <> (to_jsonb(old) - 'status' - 'updated_at');
 if old.status='closed' or old.status='cancelled' then
  if new.status is distinct from old.status or v_has_content_changes then raise exception 'closed or cancelled requests are immutable'; end if;
 end if;
 if old.status='draft' and new.status not in ('draft','open','cancelled') then raise exception 'invalid buyer request status transition'; end if;
 if old.status='open' and new.status not in ('open','closed','cancelled') then raise exception 'invalid buyer request status transition'; end if;
 if v_has_content_changes then
  select exists(select 1 from public.rfqs r join public.quotations q on q.rfq_id=r.id where r.buyer_request_id=old.id) into v_has_quotes;
  if v_has_quotes then raise exception 'buyer request terms cannot change after supplier quotations have been submitted'; end if;
  if old.status not in ('draft','open') then raise exception 'buyer request is not editable in this status'; end if;
 end if;
 return new;
end; $$;
drop trigger if exists trg_guard_buyer_request_update on public.buyer_requests;
create trigger trg_guard_buyer_request_update before update on public.buyer_requests for each row execute function public.guard_buyer_request_update();

create or replace function public.publish_buyer_request_with_rfq(
 p_company_id uuid,p_title text,p_description text,p_category_id uuid default null,
 p_quantity numeric default null,p_unit text default null,p_destination_country char(2) default null,
 p_target_delivery_date date default null
) returns uuid language plpgsql security definer set search_path = '' as $$
declare v_request uuid; v_ref text;
begin
 if auth.uid() is null or not public.is_company_manager(p_company_id) then raise exception 'forbidden' using errcode='42501'; end if;
 if length(trim(coalesce(p_title,'')))<2 or length(trim(coalesce(p_description,'')))<2 then raise exception 'title and description are required'; end if;
 if p_quantity is not null and p_quantity<=0 then raise exception 'quantity must be positive'; end if;
 insert into public.buyer_requests(buyer_company_id,created_by,title,description,product_category_id,quantity,unit,destination_country,target_delivery_date,status)
 values(p_company_id,auth.uid(),trim(p_title),trim(p_description),p_category_id,p_quantity,p_unit,upper(p_destination_country),p_target_delivery_date,'open') returning id into v_request;
 v_ref:='ZQ-'||to_char(now(),'YYYY')||'-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,8));
 insert into public.rfqs(buyer_request_id,reference_code,published_at) values(v_request,v_ref,now());
 return v_request;
end; $$;
revoke all on function public.publish_buyer_request_with_rfq(uuid,text,text,uuid,numeric,text,char(2),date) from public,anon;
grant execute on function public.publish_buyer_request_with_rfq(uuid,text,text,uuid,numeric,text,char(2),date) to authenticated;

create or replace function public.open_existing_buyer_request(p_request_id uuid)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_company uuid; v_status public.rfq_status; v_rfq uuid; v_ref text;
begin
 select buyer_company_id,status into v_company,v_status from public.buyer_requests where id=p_request_id for update;
 if v_company is null or not public.is_company_manager(v_company) then raise exception 'forbidden' using errcode='42501'; end if;
 if v_status<>'draft' then raise exception 'only draft requests can be opened'; end if;
 update public.buyer_requests set status='open' where id=p_request_id;
 select id into v_rfq from public.rfqs where buyer_request_id=p_request_id;
 if v_rfq is null then
  v_ref:='ZQ-'||to_char(now(),'YYYY')||'-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,8));
  insert into public.rfqs(buyer_request_id,reference_code,published_at) values(p_request_id,v_ref,now()) returning id into v_rfq;
 end if;
 return v_rfq;
end; $$;
revoke all on function public.open_existing_buyer_request(uuid) from public,anon;
grant execute on function public.open_existing_buyer_request(uuid) to authenticated;

create or replace function public.notify_company_activity()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_user uuid;
begin
 for v_user in select user_id from public.company_members where company_id=new.id and user_id<>auth.uid() loop
  insert into public.notifications(user_id,type,title,body,data)
  values(v_user,'company_activity','Company profile updated','A company administrator updated the company profile.',jsonb_build_object('company_id',new.id));
 end loop;
 return new;
end; $$;
drop trigger if exists trg_notify_company_activity on public.companies;
create trigger trg_notify_company_activity after update of legal_name,display_name,description,website_url,country_code,city,address,industry,company_type,contact_email,phone,logo_path on public.companies for each row execute function public.notify_company_activity();

create or replace function public.notify_company_member_added()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_user uuid; v_company_name text;
begin
 select display_name into v_company_name from public.companies where id=new.company_id;
 for v_user in select user_id from public.company_members where company_id=new.company_id and user_id<>new.user_id loop
  insert into public.notifications(user_id,type,title,body,data)
  values(v_user,'company_activity','New company member',coalesce(v_company_name,'Your company')||' has a new member.',jsonb_build_object('company_id',new.company_id,'user_id',new.user_id));
 end loop;
 return new;
end; $$;
drop trigger if exists trg_notify_company_member_added on public.company_members;
create trigger trg_notify_company_member_added after insert on public.company_members for each row execute function public.notify_company_member_added();

-- Notify suppliers only after the RFQ row exists, so the notification carries a valid RFQ id.
drop trigger if exists trg_notify_open_rfq_insert on public.buyer_requests;
drop trigger if exists trg_notify_open_rfq_update on public.buyer_requests;
create or replace function public.notify_new_rfq()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_buyer_company uuid; v_user uuid;
begin
 select buyer_company_id into v_buyer_company from public.buyer_requests where id=new.buyer_request_id;
 for v_user in select distinct m.user_id from public.company_members m join public.users u on u.id=m.user_id where u.role='supplier' and m.company_id<>v_buyer_company loop
  insert into public.notifications(user_id,type,title,body,data)
  values(v_user,'rfq_opened','New buyer request','A buyer request is now open for supplier responses.',jsonb_build_object('buyer_request_id',new.buyer_request_id,'rfq_id',new.id));
 end loop;
 return new;
end; $$;
drop trigger if exists trg_notify_new_rfq on public.rfqs;
create trigger trg_notify_new_rfq after insert on public.rfqs for each row execute function public.notify_new_rfq();

-- The baseline quotation schema has quantity but no distinct MOQ field. Add it safely.
alter table public.quotations add column if not exists minimum_order_quantity numeric(14,3);
do $$ begin
 if not exists(select 1 from pg_constraint where conname='quotation_moq_nonnegative' and conrelid='public.quotations'::regclass) then
  alter table public.quotations add constraint quotation_moq_nonnegative check(minimum_order_quantity is null or minimum_order_quantity>=0);
 end if;
end $$;

drop function if exists public.revise_quotation(uuid,numeric,char(3),numeric,integer,date,text);
create or replace function public.revise_quotation(p_quotation_id uuid,p_unit_price numeric,p_currency char(3),p_quantity numeric,p_minimum_order_quantity numeric,p_lead_time_days integer,p_validity_date date,p_notes text)
returns void language plpgsql security definer set search_path = '' as $$
declare v public.quotations%rowtype;
begin
 select * into v from public.quotations where id=p_quotation_id for update;
 if not found or not public.is_company_manager(v.supplier_company_id) then raise exception 'forbidden' using errcode='42501'; end if;
 if v.status not in ('submitted','revised') then raise exception 'quotation cannot be revised in its current status'; end if;
 if p_unit_price<0 or p_quantity<=0 or (p_minimum_order_quantity is not null and p_minimum_order_quantity<0) or (p_lead_time_days is not null and p_lead_time_days<0) then raise exception 'invalid quotation terms'; end if;
 if p_currency !~ '^[A-Za-z]{3}$' then raise exception 'currency must be a three-letter ISO code'; end if;
 update public.quotations set unit_price=p_unit_price,currency=upper(p_currency),quantity=p_quantity,minimum_order_quantity=p_minimum_order_quantity,lead_time_days=p_lead_time_days,validity_date=p_validity_date,notes=coalesce(p_notes,''),status='revised' where id=p_quotation_id;
end; $$;
revoke all on function public.revise_quotation(uuid,numeric,char(3),numeric,numeric,integer,date,text) from public,anon;
grant execute on function public.revise_quotation(uuid,numeric,char(3),numeric,numeric,integer,date,text) to authenticated;

create or replace function public.create_company_invitation(p_company_id uuid,p_email text,p_role public.company_member_role default 'member')
returns text language plpgsql security definer set search_path = '' as $$
declare v_token text; v_email text; v_actor_role public.company_member_role;
begin
 if auth.uid() is null or not public.is_company_manager(p_company_id) then raise exception 'forbidden' using errcode='42501'; end if;
 v_email := lower(trim(p_email));
 if v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then raise exception 'invalid email'; end if;
 if p_role not in ('admin','member') then raise exception 'invalid invitation role'; end if;
 select role into v_actor_role from public.company_members where company_id=p_company_id and user_id=auth.uid();
 if p_role='admin' and v_actor_role<>'owner' then raise exception 'only owner can invite an admin' using errcode='42501'; end if;
 v_token := encode(public.gen_random_bytes(32),'hex');
 insert into public.company_invitations(company_id,invited_email,invited_role,token_hash,invited_by)
 values(p_company_id,v_email,p_role,encode(public.digest(v_token,'sha256'),'hex'),auth.uid());
 return v_token;
end; $$;
revoke all on function public.create_company_invitation(uuid,text,public.company_member_role) from public,anon;
grant execute on function public.create_company_invitation(uuid,text,public.company_member_role) to authenticated;

create or replace function public.publish_buyer_request_with_rfq(
 p_company_id uuid,p_title text,p_description text,p_category_id uuid default null,
 p_quantity numeric default null,p_unit text default null,p_destination_country char(2) default null,
 p_target_delivery_date date default null
) returns uuid language plpgsql security definer set search_path = '' as $$
declare v_request uuid; v_ref text;
begin
 if auth.uid() is null or not public.is_company_manager(p_company_id) then raise exception 'forbidden' using errcode='42501'; end if;
 if length(trim(coalesce(p_title,'')))<2 or length(trim(coalesce(p_description,'')))<2 then raise exception 'title and description are required'; end if;
 if p_quantity is null or p_quantity<=0 or length(trim(coalesce(p_unit,'')))=0 then raise exception 'positive quantity and unit are required'; end if;
 if p_destination_country is null or upper(p_destination_country) !~ '^[A-Z]{2}$' then raise exception 'destination country must be an ISO-2 code'; end if;
 insert into public.buyer_requests(buyer_company_id,created_by,title,description,product_category_id,quantity,unit,destination_country,target_delivery_date,status)
 values(p_company_id,auth.uid(),trim(p_title),trim(p_description),p_category_id,p_quantity,trim(p_unit),upper(p_destination_country),p_target_delivery_date,'open') returning id into v_request;
 v_ref:='ZQ-'||to_char(now(),'YYYY')||'-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,8));
 insert into public.rfqs(buyer_request_id,reference_code,published_at) values(v_request,v_ref,now());
 return v_request;
end; $$;
revoke all on function public.publish_buyer_request_with_rfq(uuid,text,text,uuid,numeric,text,char(2),date) from public,anon;
grant execute on function public.publish_buyer_request_with_rfq(uuid,text,text,uuid,numeric,text,char(2),date) to authenticated;

-- Any company-side catalogue edit sends a previously published listing back to moderation.
create or replace function public.require_product_re_review()
returns trigger language plpgsql set search_path = '' as $$
begin
 if not public.is_platform_admin() and (
  new.category_id is distinct from old.category_id or new.name is distinct from old.name or
  new.slug is distinct from old.slug or new.description is distinct from old.description or
  new.specifications is distinct from old.specifications or new.minimum_order_quantity is distinct from old.minimum_order_quantity or
  new.unit is distinct from old.unit or new.price_min is distinct from old.price_min or
  new.price_max is distinct from old.price_max or new.currency is distinct from old.currency or
  new.origin_country is distinct from old.origin_country or new.image_paths is distinct from old.image_paths
 ) then new.status:='pending_review'; end if;
 return new;
end; $$;
drop trigger if exists trg_require_product_re_review on public.products;
create trigger trg_require_product_re_review before update on public.products for each row execute function public.require_product_re_review();
