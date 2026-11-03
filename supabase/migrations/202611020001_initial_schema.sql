-- NEXVORA B2B / Supabase PostgreSQL foundation
-- Apply in a fresh Supabase project using SQL Editor or Supabase CLI.
create extension if not exists pgcrypto;

create type public.platform_role as enum ('buyer','supplier','platform_admin');
create type public.company_member_role as enum ('owner','admin','member');
create type public.product_status as enum ('draft','pending_review','published','rejected','archived');
create type public.rfq_status as enum ('draft','open','closed','cancelled');
create type public.quotation_status as enum ('submitted','revised','accepted','rejected','withdrawn');
create type public.verification_status as enum ('not_submitted','pending','verified','rejected');

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$ begin new.updated_at = now(); return new; end; $$;

create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  full_name text not null default '',
  role public.platform_role not null default 'buyer',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint users_name_length check (char_length(full_name) <= 160)
);

create table public.companies (
  id uuid primary key default gen_random_uuid(),
  legal_name text not null,
  display_name text not null,
  slug text not null unique,
  description text not null default '',
  website_url text,
  country_code char(2),
  city text,
  address text,
  industry text,
  company_type text,
  contact_email text,
  phone text,
  logo_path text,
  verification_status public.verification_status not null default 'not_submitted',
  is_active boolean not null default true,
  created_by uuid not null references public.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint companies_name_length check (char_length(legal_name) between 2 and 200),
  constraint companies_slug_format check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  constraint companies_country_format check (country_code is null or country_code ~ '^[A-Z]{2}$')
);

create table public.company_members (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  role public.company_member_role not null default 'member',
  invited_by uuid references public.users(id),
  joined_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique(company_id,user_id)
);

create table public.business_profiles (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null unique references public.companies(id) on delete cascade,
  year_established smallint,
  employee_range text,
  annual_revenue_range text,
  certifications text[] not null default '{}',
  export_markets text[] not null default '{}',
  capabilities text[] not null default '{}',
  languages text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint business_profile_year check (year_established is null or year_established between 1800 and 2100)
);

create table public.product_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text not null unique,
  parent_id uuid references public.product_categories(id),
  description text not null default '',
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  category_id uuid references public.product_categories(id),
  name text not null,
  slug text not null,
  description text not null default '',
  specifications jsonb not null default '{}'::jsonb,
  minimum_order_quantity numeric(14,3),
  unit text,
  price_min numeric(14,2),
  price_max numeric(14,2),
  currency char(3),
  origin_country char(2),
  image_paths text[] not null default '{}',
  status public.product_status not null default 'pending_review',
  created_by uuid not null references public.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id,slug),
  constraint products_name_length check (char_length(name) between 2 and 180),
  constraint products_moq_nonnegative check (minimum_order_quantity is null or minimum_order_quantity >= 0),
  constraint products_price_range check (price_min is null or price_max is null or price_max >= price_min)
);

create table public.buyer_requests (
  id uuid primary key default gen_random_uuid(),
  buyer_company_id uuid not null references public.companies(id),
  created_by uuid not null references public.users(id),
  title text not null,
  description text not null,
  product_category_id uuid references public.product_categories(id),
  quantity numeric(14,3),
  unit text,
  destination_country char(2),
  target_delivery_date date,
  status public.rfq_status not null default 'draft',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint buyer_requests_quantity check (quantity is null or quantity > 0)
);

create table public.rfqs (
  id uuid primary key default gen_random_uuid(),
  buyer_request_id uuid not null unique references public.buyer_requests(id) on delete cascade,
  reference_code text not null unique,
  published_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint rfqs_expiry check (expires_at is null or published_at is null or expires_at > published_at)
);

create table public.quotations (
  id uuid primary key default gen_random_uuid(),
  rfq_id uuid not null references public.rfqs(id) on delete cascade,
  supplier_company_id uuid not null references public.companies(id),
  submitted_by uuid not null references public.users(id),
  unit_price numeric(14,2) not null,
  currency char(3) not null,
  quantity numeric(14,3) not null,
  lead_time_days integer,
  incoterm text,
  validity_date date,
  notes text not null default '',
  status public.quotation_status not null default 'submitted',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(rfq_id,supplier_company_id),
  constraint quotation_positive check (unit_price >= 0 and quantity > 0),
  constraint quotation_lead_time check (lead_time_days is null or lead_time_days >= 0)
);

create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  buyer_company_id uuid not null references public.companies(id),
  supplier_company_id uuid not null references public.companies(id),
  rfq_id uuid references public.rfqs(id) on delete set null,
  created_by uuid not null references public.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(buyer_company_id,supplier_company_id,rfq_id),
  constraint conversation_companies_differ check (buyer_company_id <> supplier_company_id)
);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.users(id),
  body text not null,
  attachment_path text,
  read_at timestamptz,
  created_at timestamptz not null default now(),
  constraint message_body_length check (char_length(body) between 1 and 10000)
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  type text not null,
  title text not null,
  body text not null default '',
  data jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.verification_documents (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  uploaded_by uuid not null references public.users(id),
  document_type text not null,
  storage_path text not null unique,
  original_filename text not null,
  mime_type text not null,
  file_size_bytes bigint not null,
  status public.verification_status not null default 'pending',
  created_at timestamptz not null default now(),
  constraint verification_file_size check (file_size_bytes between 1 and 10485760)
);

create table public.verification_records (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  document_id uuid references public.verification_documents(id) on delete set null,
  reviewed_by uuid references public.users(id),
  status public.verification_status not null default 'pending',
  review_notes text not null default '',
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.users(id),
  target_type text not null,
  target_id uuid not null,
  reason text not null,
  details text not null default '',
  status text not null default 'open',
  assigned_to uuid references public.users(id),
  resolution text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint reports_target_type check (target_type in ('company','product','user','message'))
);

-- Auth trigger: role is restricted to buyer/supplier at signup. Platform admin is assigned manually by a trusted operator.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_role public.platform_role; v_name text;
begin
  v_role := case when new.raw_user_meta_data ->> 'account_type' = 'supplier' then 'supplier'::public.platform_role else 'buyer'::public.platform_role end;
  v_name := coalesce(nullif(trim(new.raw_user_meta_data ->> 'full_name'),''), split_part(new.email,'@',1));
  insert into public.users(id,email,full_name,role) values(new.id,new.email,v_name,v_role);
  return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

create or replace function public.is_platform_admin()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.users u where u.id = (select auth.uid()) and u.role = 'platform_admin' and u.is_active = true);
$$;
create or replace function public.is_company_member(p_company_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.company_members m where m.company_id=p_company_id and m.user_id=(select auth.uid()));
$$;
create or replace function public.is_company_manager(p_company_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.company_members m where m.company_id=p_company_id and m.user_id=(select auth.uid()) and m.role in ('owner','admin'));
$$;

-- Updated-at triggers
DO $$ DECLARE t text; BEGIN
 FOREACH t IN ARRAY ARRAY['users','companies','business_profiles','product_categories','products','buyer_requests','rfqs','quotations','conversations','reports'] LOOP
  EXECUTE format('drop trigger if exists set_updated_at on public.%I',t);
  EXECUTE format('create trigger set_updated_at before update on public.%I for each row execute function public.set_updated_at()',t);
 END LOOP;
END $$;

-- Indexes for marketplace, RFQ, messaging and admin operations
create index products_search_idx on public.products using gin (to_tsvector('simple', coalesce(name,'') || ' ' || coalesce(description,'')));
create index products_company_status_idx on public.products(company_id,status,created_at desc);
create index products_category_status_idx on public.products(category_id,status);
create index companies_country_industry_idx on public.companies(country_code,industry);
create index company_members_user_idx on public.company_members(user_id,company_id);
create index buyer_requests_status_created_idx on public.buyer_requests(status,created_at desc);
create index rfqs_expiry_idx on public.rfqs(expires_at);
create index quotations_rfq_idx on public.quotations(rfq_id,status);
create index messages_conversation_created_idx on public.messages(conversation_id,created_at);
create index notifications_user_unread_idx on public.notifications(user_id,created_at desc) where read_at is null;
create index reports_status_created_idx on public.reports(status,created_at desc);

-- RLS enabled on every application table
DO $$ DECLARE t text; BEGIN
 FOREACH t IN ARRAY ARRAY['users','companies','company_members','business_profiles','product_categories','products','buyer_requests','rfqs','quotations','conversations','messages','notifications','verification_documents','verification_records','reports'] LOOP
  EXECUTE format('alter table public.%I enable row level security',t);
 END LOOP;
END $$;

-- Users: self-read/update only non-privileged fields. Role and active status cannot be changed by user policies.
create policy users_select_self_or_admin on public.users for select using (id=(select auth.uid()) or public.is_platform_admin());
create policy users_update_self_profile on public.users for update using (id=(select auth.uid())) with check (id=(select auth.uid()));
-- Restrict column-level writes so a normal authenticated user cannot modify role/email/active status.
revoke update on public.users from authenticated;
grant update (full_name) on public.users to authenticated;

create policy companies_public_read on public.companies for select using (is_active=true or public.is_company_member(id) or public.is_platform_admin());
create policy companies_create_self on public.companies for insert with check (created_by=(select auth.uid()));
create policy companies_manager_update on public.companies for update using (public.is_company_manager(id) or public.is_platform_admin()) with check (public.is_company_manager(id) or public.is_platform_admin());
create policy companies_admin_delete on public.companies for delete using (public.is_platform_admin());

create policy members_read_related on public.company_members for select using (user_id=(select auth.uid()) or public.is_company_member(company_id) or public.is_platform_admin());
create policy members_owner_create on public.company_members for insert with check (
  user_id=(select auth.uid()) and role='owner' and exists(select 1 from public.companies c where c.id=company_id and c.created_by=(select auth.uid()))
);
create policy members_manager_update on public.company_members for update using (public.is_company_manager(company_id) or public.is_platform_admin()) with check (public.is_company_manager(company_id) or public.is_platform_admin());
create policy members_manager_delete on public.company_members for delete using (public.is_company_manager(company_id) or public.is_platform_admin());

create policy business_profiles_read_public on public.business_profiles for select using (exists(select 1 from public.companies c where c.id=company_id and c.is_active=true) or public.is_company_member(company_id) or public.is_platform_admin());
create policy business_profiles_manager_write on public.business_profiles for all using (public.is_company_manager(company_id) or public.is_platform_admin()) with check (public.is_company_manager(company_id) or public.is_platform_admin());

create policy categories_read_active on public.product_categories for select using (is_active=true or public.is_platform_admin());
create policy categories_admin_write on public.product_categories for all using (public.is_platform_admin()) with check (public.is_platform_admin());

create policy products_read_published on public.products for select using (status='published' or public.is_company_member(company_id) or public.is_platform_admin());
create policy products_company_write on public.products for insert with check (public.is_company_manager(company_id) and created_by=(select auth.uid()));
create policy products_company_update on public.products for update using (public.is_company_manager(company_id) or public.is_platform_admin()) with check (public.is_company_manager(company_id) or public.is_platform_admin());
create policy products_company_delete on public.products for delete using (public.is_company_manager(company_id) or public.is_platform_admin());

create policy buyer_requests_read on public.buyer_requests for select using (public.is_company_member(buyer_company_id) or status='open' or public.is_platform_admin());
create policy buyer_requests_create on public.buyer_requests for insert with check (public.is_company_manager(buyer_company_id) and created_by=(select auth.uid()));
create policy buyer_requests_update on public.buyer_requests for update using (public.is_company_manager(buyer_company_id) or public.is_platform_admin()) with check (public.is_company_manager(buyer_company_id) or public.is_platform_admin());
create policy buyer_requests_delete on public.buyer_requests for delete using (public.is_company_manager(buyer_company_id) or public.is_platform_admin());

create policy rfqs_read_open_or_related on public.rfqs for select using (exists(select 1 from public.buyer_requests b where b.id=buyer_request_id and (b.status='open' or public.is_company_member(b.buyer_company_id))) or public.is_platform_admin());
create policy rfqs_buyer_manage on public.rfqs for all using (exists(select 1 from public.buyer_requests b where b.id=buyer_request_id and public.is_company_manager(b.buyer_company_id)) or public.is_platform_admin()) with check (exists(select 1 from public.buyer_requests b where b.id=buyer_request_id and public.is_company_manager(b.buyer_company_id)) or public.is_platform_admin());

create policy quotations_read_parties on public.quotations for select using (public.is_company_member(supplier_company_id) or exists(select 1 from public.rfqs r join public.buyer_requests b on b.id=r.buyer_request_id where r.id=rfq_id and public.is_company_member(b.buyer_company_id)) or public.is_platform_admin());
create policy quotations_supplier_create on public.quotations for insert with check (public.is_company_manager(supplier_company_id) and submitted_by=(select auth.uid()) and exists(select 1 from public.rfqs r join public.buyer_requests b on b.id=r.buyer_request_id where r.id=rfq_id and b.status='open'));
create policy quotations_supplier_update on public.quotations for update using (public.is_company_manager(supplier_company_id) or public.is_platform_admin()) with check (public.is_company_manager(supplier_company_id) or public.is_platform_admin());
create policy quotations_buyer_decision on public.quotations for update using (exists(select 1 from public.rfqs r join public.buyer_requests b on b.id=r.buyer_request_id where r.id=rfq_id and public.is_company_manager(b.buyer_company_id))) with check (exists(select 1 from public.rfqs r join public.buyer_requests b on b.id=r.buyer_request_id where r.id=rfq_id and public.is_company_manager(b.buyer_company_id))); 

create policy conversations_participant_read on public.conversations for select using (public.is_company_member(buyer_company_id) or public.is_company_member(supplier_company_id) or public.is_platform_admin());
create policy conversations_participant_create on public.conversations for insert with check (public.is_company_manager(buyer_company_id) or public.is_company_manager(supplier_company_id));
create policy messages_participant_read on public.messages for select using (exists(select 1 from public.conversations c where c.id=conversation_id and (public.is_company_member(c.buyer_company_id) or public.is_company_member(c.supplier_company_id))) or public.is_platform_admin());
create policy messages_participant_send on public.messages for insert with check (sender_id=(select auth.uid()) and exists(select 1 from public.conversations c where c.id=conversation_id and (public.is_company_member(c.buyer_company_id) or public.is_company_member(c.supplier_company_id))));
create policy messages_sender_update on public.messages for update using (sender_id=(select auth.uid())) with check (sender_id=(select auth.uid()));

create policy notifications_self_read on public.notifications for select using (user_id=(select auth.uid()) or public.is_platform_admin());
create policy notifications_self_update on public.notifications for update using (user_id=(select auth.uid())) with check (user_id=(select auth.uid()));

create policy verification_docs_member_read on public.verification_documents for select using (public.is_company_member(company_id) or public.is_platform_admin());
create policy verification_docs_manager_insert on public.verification_documents for insert with check (public.is_company_manager(company_id) and uploaded_by=(select auth.uid()));
create policy verification_records_member_read on public.verification_records for select using (public.is_company_member(company_id) or public.is_platform_admin());
create policy verification_records_admin_write on public.verification_records for all using (public.is_platform_admin()) with check (public.is_platform_admin());

create policy reports_create_self on public.reports for insert with check (reporter_id=(select auth.uid()));
create policy reports_read_reporter_or_admin on public.reports for select using (reporter_id=(select auth.uid()) or public.is_platform_admin());
create policy reports_admin_update on public.reports for update using (public.is_platform_admin()) with check (public.is_platform_admin());

-- Minimal admin metrics RPC; all underlying rows remain protected by RLS.
create or replace function public.nexvora_admin_overview()
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare result jsonb;
begin
  if not public.is_platform_admin() then raise exception 'forbidden' using errcode='42501'; end if;
  select jsonb_build_object(
    'users',(select count(*) from public.users),
    'companies',(select count(*) from public.companies),
    'products',(select count(*) from public.products),
    'published_products',(select count(*) from public.products where status='published'),
    'rfqs',(select count(*) from public.rfqs),
    'open_rfqs',(select count(*) from public.buyer_requests where status='open'),
    'pending_verifications',(select count(*) from public.verification_documents where status='pending'),
    'open_reports',(select count(*) from public.reports where status='open')
  ) into result;
  return result;
end; $$;
grant execute on function public.nexvora_admin_overview() to authenticated;

-- Starter categories (safe to re-run)
insert into public.product_categories(name,slug,sort_order) values
 ('Agri & Food','agri-food',1),('Industrial','industrial',2),('Packaging','packaging',3),('Technology','technology',4)
on conflict (slug) do nothing;

-- Create this private bucket in Supabase Storage. Upload policy restricts files to company members;
-- application must validate MIME, extension and size before upload. Never expose private docs publicly.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('company-verification','company-verification',false,10485760,array['application/pdf','image/jpeg','image/png'])
on conflict (id) do nothing;
create policy verification_storage_read on storage.objects for select to authenticated
using (bucket_id='company-verification' and exists(
 select 1 from public.verification_documents d
 where d.storage_path=name and public.is_company_member(d.company_id)
));
create policy verification_storage_insert on storage.objects for insert to authenticated
with check (bucket_id='company-verification' and (storage.foldername(name))[1] = auth.uid()::text);

-- IMPORTANT: Do not grant client access to admin role assignment. Promote an administrator manually:
-- update public.users set role='platform_admin' where email='trusted-admin@your-domain.com';
