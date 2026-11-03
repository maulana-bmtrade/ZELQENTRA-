-- NEXVORA B2B Phase 2.1 hardening patch.
-- Apply ONLY after 202611020001_initial_schema.sql on the same Supabase project.
-- This narrows public company-row access while retaining a deliberately limited directory view.

-- Do not expose private company columns (contact_email, phone, address, etc.) to anonymous visitors.
drop policy if exists companies_public_read on public.companies;
create policy companies_member_or_admin_read on public.companies
  for select to authenticated
  using (public.is_company_member(id) or public.is_platform_admin());

-- Public-safe company directory. View exposes only fields intended for marketplace display.
create or replace view public.public_company_directory
with (security_barrier = true) as
select id, display_name, country_code, industry, logo_path
from public.companies
where is_active = true;

grant select on public.public_company_directory to anon, authenticated;

-- Ensure the view does not become an accidental write surface.
revoke insert, update, delete, truncate, references, trigger
  on public.public_company_directory from anon, authenticated;

-- Additional indexes supporting common foreign-key joins and chronological views.
create index if not exists products_created_at_idx on public.products(created_at desc);
create index if not exists buyer_requests_company_created_idx on public.buyer_requests(buyer_company_id, created_at desc);
create index if not exists quotations_supplier_created_idx on public.quotations(supplier_company_id, created_at desc);
create index if not exists verification_documents_company_created_idx on public.verification_documents(company_id, created_at desc);
create index if not exists conversations_buyer_company_idx on public.conversations(buyer_company_id, created_at desc);
create index if not exists conversations_supplier_company_idx on public.conversations(supplier_company_id, created_at desc);

-- Note: this patch intentionally does not claim to solve all column-level authorization concerns.
-- See PHASE21_AUDIT.md and run the two-account RLS tests before production use.
