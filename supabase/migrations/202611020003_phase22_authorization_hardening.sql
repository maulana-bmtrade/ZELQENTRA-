-- NEXVORA B2B Phase 2.2 authorization hardening.
-- Apply ONLY after migrations 001 and 002, on the same project.
-- This migration intentionally removes direct client-side membership administration.

-- 1) Membership is security-sensitive. Only the trusted workspace RPC may create
--    the initial owner membership. Invitations/member management are not shipped yet.
drop policy if exists members_owner_create on public.company_members;
drop policy if exists members_manager_update on public.company_members;
drop policy if exists members_manager_delete on public.company_members;
revoke insert, update, delete on public.company_members from anon, authenticated;
grant select on public.company_members to authenticated;

-- 2) Company creation and initial owner membership happen atomically in one RPC.
--    The caller cannot choose created_by, owner user_id, or owner role.
revoke insert on public.companies from anon, authenticated;
create or replace function public.create_company_workspace(p_company_name text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_name text := nullif(trim(p_company_name), '');
  v_company_id uuid;
  v_slug text;
begin
  if v_user is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  if v_name is null or char_length(v_name) < 2 or char_length(v_name) > 200 then
    raise exception 'company name must be between 2 and 200 characters' using errcode = '22023';
  end if;

  -- Serialize first-workspace creation for this Auth user to avoid duplicate
  -- companies if signup callback and SIGNED_IN event race each other.
  perform pg_advisory_xact_lock(hashtextextended(v_user::text, 0));

  select m.company_id into v_company_id
  from public.company_members m
  where m.user_id = v_user
  order by m.joined_at
  limit 1;
  if v_company_id is not null then
    return v_company_id;
  end if;

  v_slug := trim(both '-' from regexp_replace(lower(v_name), '[^a-z0-9]+', '-', 'g'));
  if v_slug = '' then v_slug := 'company'; end if;
  v_slug := left(v_slug, 170) || '-' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 8);

  insert into public.companies(legal_name, display_name, slug, created_by)
  values (v_name, v_name, v_slug, v_user)
  returning id into v_company_id;

  insert into public.company_members(company_id, user_id, role)
  values (v_company_id, v_user, 'owner');

  return v_company_id;
end;
$$;
revoke all on function public.create_company_workspace(text) from public, anon;
grant execute on function public.create_company_workspace(text) to authenticated;

-- 3) Restrict company updates to profile fields. Ownership, active/verification
--    state and slug are not editable by normal browser clients.
revoke update on public.companies from anon, authenticated;
grant update (legal_name, display_name, description, website_url, country_code,
              city, address, industry, company_type, contact_email, phone, logo_path)
on public.companies to authenticated;

-- 4) Product managers may edit listing content, but cannot self-publish or alter
--    company ownership/creator/status through direct PostgREST updates.
revoke update on public.products from anon, authenticated;
grant update (category_id, name, slug, description, specifications,
              minimum_order_quantity, unit, price_min, price_max, currency,
              origin_country, image_paths)
on public.products to authenticated;

-- 5) Buyer request identity/ownership is immutable. The owning company manager
--    may update request content and lifecycle status.
revoke update on public.buyer_requests from anon, authenticated;
grant update (title, description, product_category_id, quantity, unit,
              destination_country, target_delivery_date, status)
on public.buyer_requests to authenticated;

-- 6) Quotation commercial terms are immutable through direct browser updates.
--    Buyer and supplier can only update status; the trigger validates the
--    permitted transition against the authenticated party.
revoke update on public.quotations from anon, authenticated;
grant update (status) on public.quotations to authenticated;

drop policy if exists quotations_supplier_update on public.quotations;
drop policy if exists quotations_buyer_decision on public.quotations;
create policy quotations_status_update_supplier on public.quotations
for update to authenticated
using (public.is_company_manager(supplier_company_id) or public.is_platform_admin())
with check (public.is_company_manager(supplier_company_id) or public.is_platform_admin());
create policy quotations_status_update_buyer on public.quotations
for update to authenticated
using (exists (
  select 1 from public.rfqs r
  join public.buyer_requests b on b.id = r.buyer_request_id
  where r.id = rfq_id and public.is_company_manager(b.buyer_company_id)
))
with check (exists (
  select 1 from public.rfqs r
  join public.buyer_requests b on b.id = r.buyer_request_id
  where r.id = rfq_id and public.is_company_manager(b.buyer_company_id)
));

create or replace function public.guard_quotation_status_change()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_is_supplier boolean;
  v_is_buyer boolean;
begin
  if (to_jsonb(new) - 'status' - 'updated_at') <> (to_jsonb(old) - 'status' - 'updated_at') then
    raise exception 'quotation commercial fields are immutable through client updates' using errcode = '42501';
  end if;
  if public.is_platform_admin() then return new; end if;

  v_is_supplier := public.is_company_manager(old.supplier_company_id);
  select public.is_company_manager(b.buyer_company_id) into v_is_buyer
  from public.rfqs r join public.buyer_requests b on b.id = r.buyer_request_id
  where r.id = old.rfq_id;

  if v_is_supplier and old.status in ('submitted','revised')
     and new.status in ('revised','withdrawn') then return new; end if;
  if coalesce(v_is_buyer,false) and old.status in ('submitted','revised')
     and new.status in ('accepted','rejected') then return new; end if;
  raise exception 'not authorized for this quotation status transition' using errcode = '42501';
end;
$$;
drop trigger if exists guard_quotation_status_change on public.quotations;
create trigger guard_quotation_status_change before update on public.quotations
for each row execute function public.guard_quotation_status_change();

-- New quotations must start in submitted state; supplier cannot insert an
-- already accepted/rejected quotation.
drop policy if exists quotations_supplier_create on public.quotations;
create policy quotations_supplier_create on public.quotations
for insert to authenticated
with check (
  public.is_company_manager(supplier_company_id)
  and submitted_by = (select auth.uid())
  and status = 'submitted'
  and exists (
    select 1 from public.rfqs r
    join public.buyer_requests b on b.id = r.buyer_request_id
    where r.id = rfq_id and b.status = 'open'
      and (r.expires_at is null or r.expires_at > now())
  )
);

-- 7) Message sender/conversation/body identity must not be mutable from browser.
--    Read receipts are also deferred until a narrowly scoped RPC/UI is implemented.
drop policy if exists messages_sender_update on public.messages;
revoke update, delete on public.messages from anon, authenticated;
grant select, insert on public.messages to authenticated;

-- A participant may create a conversation only as themselves and only if they
-- belong to both represented companies. This prevents outsider-created threads.
drop policy if exists conversations_participant_create on public.conversations;
create policy conversations_participant_create on public.conversations
for insert to authenticated
with check (
  created_by = (select auth.uid())
  and (public.is_company_manager(buyer_company_id)
       or public.is_company_manager(supplier_company_id))
);
revoke update, delete on public.conversations from anon, authenticated;

-- 8) Notifications: clients may only mark their own notification as read.
revoke update on public.notifications from anon, authenticated;
grant update (read_at) on public.notifications to authenticated;

-- 9) Reports: prevent reporters from changing assignment/status/resolution.
revoke update on public.reports from anon, authenticated;
grant update (status, assigned_to, resolution) on public.reports to authenticated;

-- 10) Verification records remain admin-only; document metadata is append-only
--     for clients. Storage upload path must match an actual company manager.
revoke update, delete on public.verification_documents from anon, authenticated;
revoke insert, update, delete on public.verification_records from anon, authenticated;

drop policy if exists verification_storage_insert on storage.objects;
create policy verification_storage_insert on storage.objects
for insert to authenticated
with check (
  bucket_id = 'company-verification'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and public.is_company_manager(((storage.foldername(name))[2])::uuid)
);

drop policy if exists verification_storage_delete_own on storage.objects;
create policy verification_storage_delete_own on storage.objects
for delete to authenticated
using (
  bucket_id = 'company-verification'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and public.is_company_manager(((storage.foldername(name))[2])::uuid)
);

-- 11) Do not expose helper predicates as unauthenticated RPC endpoints.
revoke all on function public.is_platform_admin() from public, anon;
revoke all on function public.is_company_member(uuid) from public, anon;
revoke all on function public.is_company_manager(uuid) from public, anon;
grant execute on function public.is_platform_admin() to authenticated;
grant execute on function public.is_company_member(uuid) to authenticated;
grant execute on function public.is_company_manager(uuid) to authenticated;

-- 12) Explicit grants for public-safe marketplace read path.
grant select on public.public_company_directory to anon, authenticated;

-- 13) Prevent direct product inserts from publishing listings without review.
drop policy if exists products_company_write on public.products;
create policy products_company_write on public.products
for insert to authenticated
with check (
  public.is_company_manager(company_id)
  and created_by = (select auth.uid())
  and status = 'pending_review'
);

-- 14) RFQs may only be opened for an open buyer request; ownership is checked
--     on both old and new rows for updates.
drop policy if exists rfqs_buyer_manage on public.rfqs;
create policy rfqs_buyer_insert on public.rfqs
for insert to authenticated
with check (exists (
  select 1 from public.buyer_requests b
  where b.id = buyer_request_id and b.status = 'open'
    and public.is_company_manager(b.buyer_company_id)
));
create policy rfqs_buyer_update on public.rfqs
for update to authenticated
using (exists (
  select 1 from public.buyer_requests b
  where b.id = buyer_request_id and public.is_company_manager(b.buyer_company_id)
))
with check (exists (
  select 1 from public.buyer_requests b
  where b.id = buyer_request_id and public.is_company_manager(b.buyer_company_id)
));
create policy rfqs_buyer_delete on public.rfqs
for delete to authenticated
using (exists (
  select 1 from public.buyer_requests b
  where b.id = buyer_request_id and public.is_company_manager(b.buyer_company_id)
));

-- Admin verification workflow remains SQL/RLS protected. The browser role alone
-- is insufficient: verification_records policies still require platform_admin.
grant select, insert, update (document_id, reviewed_by, status, review_notes, reviewed_at)
on public.verification_records to authenticated;

-- 15) Admin metrics RPC is callable only by authenticated sessions; its internal
--    role check remains the decisive authorization control.
revoke all on function public.nexvora_admin_overview() from public, anon;
grant execute on function public.nexvora_admin_overview() to authenticated;
