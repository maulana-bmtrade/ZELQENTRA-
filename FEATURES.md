# Feature guide

## Public marketplace
Route: `/marketplace/`

Uses the existing Supabase browser client. Public product queries are constrained to `status = 'published'`. Available discovery controls: keyword search, category, country, listed price minimum/maximum, MOQ minimum/maximum, sort order, and pagination. Product detail route: `/marketplace/product/?id=<uuid>`.

## Company directory
Route: `/companies/`

Reads `public_company_directory` only. Current public view fields (per supplied migration): `id`, `display_name`, `country_code`, `industry`, and `logo_path`. Search and filters use the available display name, country, and industry fields. Company type, verification status, private address, contact email, and phone are not exposed by this view and are therefore not shown.

## Public company profile
Route: `/companies/profile.html?id=<uuid>`

Displays public directory fields and the company's published products. It does not query the private `companies` table.

## Not included
This source release does not ship complete company member administration, full buyer/supplier workflow UI, an admin moderation console, or AI Smart Discovery. The database contains some workflow tables and helper policies, but schema presence alone is not proof of a working end-to-end UI.

## Phase 2 operational modules

- Authenticated company workspace and owner/admin/member controls.
- Company invitation token lifecycle (email delivery external/manual).
- Company-scoped product catalogue management with pending-review moderation and product image storage.
- Buyer requests linked atomically to RFQs.
- Supplier quotation submission/revision/withdrawal and buyer decisions with status history.
- Buyer/supplier conversations with private file attachments and signed downloads.
- User-scoped notification center and platform-admin moderation dashboard.

See `PHASE2_IMPLEMENTATION.md` for the exact implementation scope and deferred items.
