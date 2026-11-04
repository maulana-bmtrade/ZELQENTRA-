# ZELQENTRA Phase 2 Core — Implementation Notes

## Baseline and architecture

This release is developed directly from `ZELQENTRA_GLOBAL_B2B_PLATFORM_FINAL_V1.0.1_AUDITED.zip`. The existing static HTML/CSS/ES-module frontend, Supabase JS v2 client, Marketplace, public Company Directory, product detail route, brand assets, domain configuration and original migrations are retained. No application rewrite or database reset was performed.

## New routes

- `/workspace/` — authenticated company workspace.
- `/workspace/admin.html` — platform-admin-only moderation dashboard.

## Implemented browser workflows

- Session-aware workspace entry and sign-out; profile name update.
- Workspace creation through existing `create_company_workspace(text)` RPC.
- Company profile editing using only the granted profile columns.
- Membership list, owner/admin role management, member removal, invitation token creation and invitation acceptance.
- Product CRUD for the current company. Product insert is forced to `pending_review`; any company-side content/image edit returns the listing to `pending_review`; managers cannot publish their own listings. Product image upload uses a public catalogue-only `product-images` bucket; stored values are HTTPS public URLs compatible with the existing Marketplace renderer.
- Buyer request create/edit/close and RFQ creation. New buyer request + RFQ is created atomically by `publish_buyer_request_with_rfq(...)`; draft opening uses `open_existing_buyer_request(uuid)`.
- Supplier RFQ discovery, quotation submission, supplier quotation revision (including a distinct MOQ field), supplier withdrawal, buyer accept/reject and status history.
- Company-to-company conversations, message history and private PDF/JPEG/PNG attachments with signed downloads.
- User-scoped notification list, unread count and mark-read actions.
- Admin metrics via existing `nexvora_admin_overview()` RPC, product moderation and company verification review.

## Deliberate constraints

- The supplied schema does not provide a transactional email service. Invitation tokens are generated and stored hashed; the authorized owner/admin must deliver the token to the invited email through a trusted channel. No email delivery is claimed.
- The supplied schema has no message read-receipt RPC/grant. The UI does not claim message read receipts and does not attempt to update `messages.read_at`.
- Product publication remains an admin moderation operation. A submitted product remains `pending_review` until a trusted platform administrator publishes it.
- No payment, escrow, invoice, shipping execution or AI service is introduced.
- Company verification document upload workflow is not included in this phase; the dashboard displays current verification status and admin can record a status decision.

## Migration

`supabase/migrations/202611040001_phase2_core.sql` and `supabase/migrations/202611040002_phase2_predeployment_security_fixes.sql` are the ordered Phase 2 migration pair. The second migration cleans up legacy Storage policy names, hardens path checks, replaces the forgeable quotation-revision GUC with private transaction context, makes notification writes best-effort, prevents destructive RFQ/request deletion, and blocks self-moderation.

**Do not run automatically.** Verify baseline migrations 001–003, back up the project, then apply 040001 immediately followed by 040002 in a controlled maintenance window. Run `supabase/PHASE2_VALIDATION_QUERIES.sql` and inspect the complete live Storage policy catalog. This build has not executed any SQL against the live project.
