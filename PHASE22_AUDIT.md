# NEXVORA B2B Phase 2.2 — Supabase Activation Readiness Audit

> **Historical identity notice (3 November 2026):** This engineering record was created when the platform used the working brand name **NEXVORA B2B**. The current public brand is **ZELQENTRA**. This historical record is retained to preserve technical provenance; references such as `NEXVORA_SUPABASE`, `window.NEXVORA`, `nexvora_admin_overview`, and the Supabase project slug `nexvora-b2b` are legacy technical identifiers and are intentionally not renamed in this rebranding release.

**Date:** 2026-11-02  
**Baseline:** existing Phase 2.1 project folder; no framework conversion or frontend rebuild.  
**Audit type:** source/schema static review plus local syntax/archive checks. No Supabase project credentials were supplied, and no live SQL/Auth/PostgREST/Storage test was performed.

## Executive result

Phase 2.2 improves activation readiness and narrows several high-risk client write paths. It does **not** prove that Supabase is connected or that migrations execute successfully on a live project. Apply migrations 001 → 002 → 003 to a fresh Supabase project, run the validation queries, and complete the multi-account test plan before treating backend activation as PASS.

## Files reviewed and changed

| File | Result | Notes |
|---|---|---|
| `backend.js` | UPDATED / static review | Signup stores company name in Auth metadata; login and `SIGNED_IN` callbacks invoke the atomic workspace RPC; marketplace shows a loading state before live results; company creation service uses the RPC. |
| `app.js` | PRESERVED | No changes; existing Phase 1 demo behavior, navigation and filter event wiring remain. |
| `supabase-config.js` | PRESERVED | Empty placeholder; no real credentials inserted. |
| `supabase-config.example.js` | REVIEWED | Uses the existing `anonKey` property; accepts publishable or legacy anon browser key. |
| Migration 001 | REVIEWED, not executed | Defines the 15 tables, Auth profile trigger, indexes, initial RLS and private bucket. Fresh-project migration; not fully idempotent. |
| Migration 002 | REVIEWED, not executed | Restricts direct public company row reads and exposes only safe directory columns. |
| Migration 003 | ADDED, static-reviewed only | Tightens membership and column-level writes; adds atomic workspace RPC; hardens quotation status transitions, messages, products, RFQs, conversations and Storage paths. |
| `VALIDATION_QUERIES.sql` | UPDATED | Adds function/column grant, Storage policy and view-definition diagnostics. |
| `BACKEND_SETUP.md` | UPDATED | Browser-on-Android setup, three-migration sequence, Auth, Storage, status badge and admin setup. |
| `TEST_PLAN.md` | UPDATED | Four-account scenario, direct API/RLS matrix, RFQ/quotation and regression checks. |
| `README.md` | UPDATED | Identifies Phase 2.2 status and migration order. |
| `PHASE21_AUDIT.md` | PRESERVED | Historical Phase 2.1 audit retained. |

## Main findings and remediation

1. **Company membership escalation:** the initial migration allowed managers to update/delete membership rows. A manager could potentially promote memberships or alter owner assignments. Migration 003 revokes browser insert/update/delete on `company_members`; member invitations/management are intentionally not available until a separately secured workflow is implemented.
2. **Workspace creation race and partial state:** the earlier browser path inserted a company and owner membership as separate requests. A failure could leave an orphan company. Migration 003 adds `create_company_workspace(text)`, which creates both in one database transaction, locks per Auth user to avoid duplicate creation races, and derives owner identity from `auth.uid()`.
3. **Email-confirmation signup:** signup previously did not resume workspace creation after confirmation. Auth metadata now stores the company name, and the signed-in callback/login path calls the idempotent workspace RPC.
4. **Company profile privilege boundary:** browser updates are restricted to profile columns. Company creator, slug, active state and verification state are not client-writable through the normal authenticated grant.
5. **Product publication:** product updates cannot change status/creator/company ownership; new product inserts must start as `pending_review`.
6. **Quotation ownership:** commercial fields are no longer client-updatable. Only `status` is granted; a trigger allows supplier transitions to revised/withdrawn and buyer transitions to accepted/rejected from submitted/revised states. New quotes must start submitted and target an open, non-expired RFQ.
7. **Message identity:** browser updates/deletes on messages are revoked; inserts must use the current Auth user as sender and a conversation in which the user belongs to a participant company.
8. **Conversation creation:** `created_by` must match the current user, who must manage at least one of the two represented companies.
9. **Private documents:** Storage upload policy checks the authenticated user's first path segment and verifies manager membership for the company in the second path segment. The bucket remains private. Server-side malware/signature inspection is still absent.
10. **Public company directory:** migration 002's view exposes only `id`, `display_name`, `country_code`, `industry`, and `logo_path`; it does not expose phone, contact email or street address.
11. **Auth profile:** `public.users.id` references `auth.users.id`; the Auth insert trigger creates the profile and the browser cannot update role/is_active. Live trigger execution and email-change synchronization still require testing.
12. **Admin access:** admin overview checks the platform role and its execute grant is narrowed to authenticated. Admin role assignment remains a trusted SQL Editor action; no admin UI is included.

## Migration order and caveats

- `202611020001_initial_schema.sql`: base schema and initial policies.
- `202611020002_phase21_public_directory_hardening.sql`: public-safe company directory.
- `202611020003_phase22_authorization_hardening.sql`: authorization/write-surface hardening and workspace RPC.

The sequence was statically reviewed for object dependencies and expected ordering. It has **not** been executed by PostgreSQL in a live project. Migration 001 is not fully idempotent; use a fresh project and never blindly rerun after a partial failure. Migration 003 uses Supabase's standard `auth.uid()`, `storage.foldername`, `storage.objects`, and PostgreSQL advisory transaction lock facilities; actual platform-version acceptance remains BLOCKED until applied.

## Frontend/backend compatibility

- Framework remains static HTML/CSS/vanilla JavaScript with Supabase JS v2 ES module.
- The 15 application tables remain: `users`, `companies`, `company_members`, `business_profiles`, `products`, `product_categories`, `buyer_requests`, `rfqs`, `quotations`, `conversations`, `messages`, `notifications`, `verification_documents`, `verification_records`, `reports`.
- Marketplace query fields match `products`, `product_categories(name)` and `public_company_directory` view columns.
- Auth metadata keys are `full_name`, `account_type`, and `company_name`; the profile trigger consumes the first two and workspace RPC receives the third from the authenticated browser session.
- The `anonKey` config property remains unchanged to avoid breaking existing config.
- Existing `app.js`, HTML structure and CSS design are preserved.

## Test results and status

| Check | Status | Evidence / limitation |
|---|---|---|
| JavaScript syntax | PASS | `node --check app.js` and `node --check backend.js` |
| Config contains no real key | PASS | `supabase-config.js` remains empty placeholder |
| Phase 1 files preserved | PASS (file-level) | `index.html`, `styles.css`, `app.js`, brand SVG retained |
| 15 table names / migration references | PASS (static) | Compared against migration 001 and validation queries |
| Migration dependency/order review | PASS (static) | 001 → 002 → 003 reviewed; no PostgreSQL execution |
| Migration SQL execution | BLOCKED | No live Supabase project |
| 15 tables, PK/FK/constraints/indexes/triggers | BLOCKED | Requires live catalog inspection after migration |
| Auth signup/login/logout/reset/session | BLOCKED | Requires project, email provider and redirects |
| Email-confirmation workspace creation | BLOCKED | Code and RPC prepared; live callback test pending |
| Marketplace live query | BLOCKED | Requires configured URL/key and applied migrations |
| Product CRUD and publication guard | BLOCKED | Direct API tests require authenticated accounts |
| RFQ/quotation and status trigger | BLOCKED | Requires Buyer A and Supplier B JWTs |
| RLS cross-account isolation | BLOCKED | Requires at least two buyer/supplier accounts |
| Storage private upload/download | BLOCKED | Requires live bucket and two-account test |
| Homepage/navigation/mobile regression | PASS (preserved source only) | Visual Android/browser test still BLOCKED |
| Product detail, CRUD screens, RFQ/quote UI, admin UI | NOT IMPLEMENTED | Service/schema fragments are not complete user-facing workflows |
| Pagination UI and server-side full-text search | NOT IMPLEMENTED | Marketplace currently fetches at most 60 records then filters in browser |
| Malware/file-signature inspection | NOT IMPLEMENTED | Requires trusted server-side processing |

## Remaining risks / release blockers

- No actual PostgreSQL parser/execution result or live Supabase catalog is available in this environment; static SQL review is not proof of successful migration.
- Direct API security tests are mandatory. In particular verify no unintended behavior from PostgreSQL column grants interacting with RLS policies.
- The public directory view relies on its view-owner access behavior; verify anonymous access returns only the five intended columns on the target Supabase/PostgreSQL version.
- RFQ visibility currently allows authenticated users to read open requests. Supplier relevance/matching is not yet implemented.
- Company invitations and member administration are intentionally blocked at the database client grant layer until a secure invitation workflow exists.
- The browser-only public key is not a secret; all data protection depends on database policies/grants.
- Product/RFQ/quotation/admin workflows are not complete UIs. Do not market the platform as a production marketplace yet.

## Release decision

**READY FOR USER-OWNED SUPABASE ACTIVATION AND TESTING — NOT LIVE-ACTIVATED, NOT PRODUCTION-CERTIFIED.** Proceed with the Android-friendly `BACKEND_SETUP.md`; do not share the publishable/anon key or any secret in chat. Report only redacted errors and validation results if further troubleshooting is needed.
