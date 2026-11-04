# Supabase Phase 2 Setup and Migration Guide

## Before applying anything

1. Confirm this is the same Supabase project configured in `supabase-config.js`.
2. In Supabase SQL Editor, verify migrations `202611020001_initial_schema.sql`, `202611020002_phase21_public_directory_hardening.sql`, and `202611020003_phase22_authorization_hardening.sql` have already been applied.
3. Back up the database and review the complete additive migration `supabase/migrations/202611040001_phase2_core.sql`.
4. Inspect existing `storage.objects` policies for all buckets. PostgreSQL permissive policies are OR-combined. Migration `202611040002_phase2_predeployment_security_fixes.sql` explicitly drops the known legacy names `conversation_attachments_read` and `conversation_attachments_insert`, plus the Phase 2 singular names, then recreates restrictive policies. Review unknown policies from the live catalog before proceeding.
5. Apply both Phase 2 migrations in order: `202611040001_phase2_core.sql`, immediately followed by `202611040002_phase2_predeployment_security_fixes.sql`. Do not expose/use Phase 2 workflows between them.
6. Run `supabase/PHASE2_VALIDATION_QUERIES.sql`; investigate any unexpected Storage policy, grant, function ACL or bucket result.
7. Confirm Auth email/redirect URLs include the production HTTPS domain and the workspace route.

## Storage layout

- `conversation-attachments` is private. Object path: `<conversation_uuid>/<uploader_user_uuid>/<filename>`. The browser uploads only PDF/JPEG/PNG up to 10 MiB and downloads through short-lived signed URLs. Do not make this bucket public.
- `product-images` is public catalogue imagery only. Object path: `<company_uuid>/<random_filename>`. Upload/delete policies require a manager of that company; public read is intentional for published marketplace imagery. Do not put contracts, identity documents or private correspondence in this bucket.

## Invitation flow

The paired migrations create `create_company_invitation(uuid,text,company_member_role)` and `accept_company_invitation(text)`. The first returns a one-time plaintext token while storing only its SHA-256 hash. Hashing resolves the installed pgcrypto extension schema instead of assuming it is on `search_path`. The invited user must sign in with the exact invited email and submit the token. Tokens expire after seven days. Email delivery is not included; share tokens only through a trusted private channel.

## Important RPCs added

- `create_company_invitation(...)`
- `accept_company_invitation(text)`
- `update_company_member_role(uuid,company_member_role)`
- `remove_company_member(uuid)`
- `publish_buyer_request_with_rfq(...)`
- `open_existing_buyer_request(uuid)`
- `revise_quotation(...)` (includes the additive `quotations.minimum_order_quantity` column)
- `moderate_product(uuid,product_status)`
- `moderate_company_verification(uuid,verification_status,text)`

The migration also adds `quotation_status_history` and database-generated notifications. Function signatures and grants are defined in the migration; do not invent alternate argument names in client code.

## Post-migration checks

Run `supabase/PHASE2_VALIDATION_QUERIES.sql`. Confirm the new RPCs, policies, triggers, tables and bucket privacy. In particular, verify no legacy broad Storage policies remain and `conversation-attachments.public=false`. Then test with two separate Auth users in two different companies: verify cross-company isolation for company data, messages, attachment download, quotations and notifications. Test owner/admin/member differences. A successful migration alone is not proof that the runtime workflows pass.

## Configuration

The website is static. Configure only the Project URL and Supabase Publishable key in `supabase-config.js`. `.env.example` is documentation and is not loaded by the browser. Never use a Supabase Secret or `service_role` key in client code.

## Security corrections in migration 040002

- Removes both plural legacy attachment policy names and singular Phase 2 policy names before recreating attachment policies.
- Enforces the exact `<conversation UUID>/<uploader UUID>/<filename>` path shape and participant membership for reads; uploads/deletes are uploader-scoped.
- Keeps conversation attachments private. Product images remain public-readable, but upload/delete require company owner/admin.
- Removes the forgeable `app.quotation_revision` GUC bypass. A private transaction-scoped context table is writable only by the database owner and is used by the revision RPC.
- Prevents direct client changes to quotation commercial columns, direct RFQ mutation, and buyer-request deletion (which could cascade-delete quotations).
- Prevents a platform admin from moderating a product or verifying a company to which that same account belongs.
- Notification triggers are best-effort and raise warnings rather than rolling back the business transaction on notification failure.
