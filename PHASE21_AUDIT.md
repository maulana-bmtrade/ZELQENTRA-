# NEXVORA B2B Phase 2.1 — Backend Activation & Integration Audit

> **Historical identity notice (3 November 2026):** This engineering record was created when the platform used the working brand name **NEXVORA B2B**. The current public brand is **ZELQENTRA**. This historical record is retained to preserve technical provenance; references such as `NEXVORA_SUPABASE`, `window.NEXVORA`, `nexvora_admin_overview`, and the Supabase project slug `nexvora-b2b` are legacy technical identifiers and are intentionally not renamed in this rebranding release.

**Audit date:** 2026-11-02  
**Baseline:** existing `NEXVORA_B2B_Foundation` project and Phase 2.0 source.  
**Scope:** static source/schema review and local automated checks. No Supabase project credentials were supplied (and none should be shared in chat), so no claim of live database/auth/security success is made.

## Executive result
Phase 2.0 is a backend foundation, not an activated backend. The JavaScript syntax passing does not establish that PostgREST relationships, RLS, storage, Auth email flows, or real SQL execution work. Phase 2.1 makes the state visible, improves the public marketplace query path, adds a narrow public-company view, provides SQL diagnostics, and documents the live activation sequence. Live integration and two-account RLS testing remain **BLOCKED** pending a user-created Supabase project.

## File-by-file audit

| File | Result | Findings |
|---|---|---|
| `backend.js` | PARTIAL / updated | Supabase client uses the configured `url` and `anonKey`; live product load previously ran only after login and silently retained sample cards on query errors/zero rows. Updated to query public listings on startup, fetch safe company directory data separately, show explicit demo/live/error status, and show an explicit zero-listing state. RFQ list now includes null expiry dates and requires open buyer requests. |
| `supabase-config.js` | PASS as placeholder | Contains no credentials. Must be filled locally/deployment-time; remains gitignored. |
| `supabase-config.example.js` | PASS with caveat | Uses legacy property name `anonKey`; both publishable and legacy anon browser keys are supported by the Supabase client. Never use service_role/secret keys. |
| `supabase/migrations/202611020001_initial_schema.sql` | REVIEW REQUIRED | Defines 15 tables and Auth profile trigger. It is a fresh-project migration, not safely rerunnable end-to-end. Broad public company row access could expose contact/address fields; fixed by the 2.1 patch. Additional update-column and membership-role authorization boundaries need live adversarial tests/hardening. |
| `supabase/migrations/202611020002_phase21_public_directory_hardening.sql` | ADDED / static-reviewed | Removes public row access to `companies`, adds authenticated member/admin read, exposes only selected public company fields through `public_company_directory`, and adds supporting indexes. Must be applied after migration 001. Not live-executed here. |
| `supabase/VALIDATION_QUERIES.sql` | ADDED | Read-only checks for 15 tables, constraints, RLS, indexes, triggers, Auth/profile consistency, bucket settings, view columns, and policies. Must be run in the user's project. |
| `BACKEND_SETUP.md` | UPDATED | Ordered setup, key safety, migration order, Auth URL, Storage, diagnostics, admin promotion, and limitations. |
| `PHASE2_AUDIT.md` | historical | Retained as Phase 2.0 baseline record; see this report for current findings. |
| `TEST_PLAN.md` | UPDATED | Adds explicit status classification and two-account test matrix. |

## Database structure review
The initial migration declares these 15 application tables:

1. `users`
2. `companies`
3. `company_members`
4. `business_profiles`
5. `products`
6. `product_categories`
7. `buyer_requests`
8. `rfqs`
9. `quotations`
10. `conversations`
11. `messages`
12. `notifications`
13. `verification_documents`
14. `verification_records`
15. `reports`

`public.users.id` references `auth.users.id` with cascade delete. The Auth insert trigger creates the public profile; this is the correct general pattern and does not duplicate password storage. Passwords remain managed by Supabase Auth. However, email changes are not synchronized by a dedicated Auth update trigger, and the trigger's behavior has not been exercised against a live project.

Foreign keys and constraints are declared in SQL, including company membership uniqueness, product slug uniqueness per company, one RFQ per buyer request, one quotation per supplier/RFQ, positive quantity/price checks, and verification file-size bounds. Actual PostgreSQL acceptance, trigger execution, and catalog state are **BLOCKED** until migration execution and diagnostics.

## Important security findings

- **Fixed in migration 002:** public access to full `companies` rows was too broad because that row includes contact email, phone, address, and other potentially private fields. Public marketplace now obtains a restricted set from `public_company_directory`.
- **Needs hardening/live test:** company-member manager update policy is broad; validate that managers cannot self-promote or manipulate owner membership beyond intended policy.
- **Needs hardening/live test:** quotation update policies are row-level but do not narrowly separate supplier-editable commercial fields from buyer decision fields. A buyer/supplier may have broader column mutation capability than the product workflow intends. Do not rely on frontend restrictions.
- **Needs hardening/live test:** message sender update policy permits sender-owned row updates without restricting which columns can change (for example, sender identity/conversation reassignment). Add column grants or immutable-field triggers before production.
- **Needs hardening/live test:** company public directory view is intentionally a safe-column view; confirm view owner/grants and anon/auth behavior in the target Supabase version.
- **Needs hardening/live test:** Storage insert policy checks the user's first folder segment; document row insertion separately checks company-manager membership. Test object upload followed by row insertion, orphan cleanup, and cross-company access.
- **Known functional gap:** signup with email confirmation enabled does not complete company workspace creation after confirmation. Current code creates company/member only when signup immediately returns a session.
- **Not implemented:** protected client routes, complete admin UI, server-side file signature checks/malware scanning, invitation flow, and complete RFQ/quotation user interfaces.

## Frontend/backend compatibility
- No framework or routing conversion was made.
- The live product query matches `products`, `product_categories`, and the new `public_company_directory` view.
- Category names in the starter SQL align with the existing category filter values (`Agri & Food`, `Industrial`, `Packaging`, `Technology`).
- Demo `app.js` still renders initial preview cards. With backend configured, `backend.js` replaces that area with live data, explicit empty state, or explicit error state; it no longer leaves the original cards looking like live records after a failed query.
- Product detail action, product image storage/gallery, and pagination UI remain unimplemented. Query currently retrieves at most 60 records.
- Service functions exist for company/product/RFQ/quotation/admin/document operations, but they are not complete dashboards or protected pages.

## Test status

| Area | Status | Evidence / reason |
|---|---|---|
| JavaScript syntax (`app.js`, `backend.js`) | PASS | Local `node --check` completed without syntax errors. |
| ZIP integrity | PASS | `unzip -t` passed for generated archive. |
| Migration table declarations (15) | PASS (static) | Static source count and names reviewed; not proof of DB creation. |
| SQL execution / constraints / FKs / triggers | BLOCKED | No live Supabase project or SQL execution context. |
| Auth signup/login/logout/reset/session | BLOCKED | Requires configured project, allowed redirects, and mail delivery. |
| Buyer/supplier role enforcement | BLOCKED | Trigger and RLS require two live accounts and direct SQL/API attempts. |
| Company workspace after email confirmation | NOT IMPLEMENTED | Post-confirmation onboarding is missing. |
| Live marketplace query | BLOCKED | Requires live Supabase and applied migrations. Query path updated but not executed against PostgREST. |
| Product CRUD / image upload / detail / pagination UI | NOT IMPLEMENTED | Service-layer fragments only; full UI absent. |
| RFQ supplier discovery / quotation comparison UI | NOT IMPLEMENTED | Partial service methods only. |
| RLS cross-account isolation | BLOCKED | Requires two independent authenticated accounts and direct API tests. |
| Private storage authorization | BLOCKED | Bucket policy is declared; real upload/download and cross-account tests not run. |
| Admin dashboard UI/moderation | NOT IMPLEMENTED | Admin RPC exists in migration; complete UI/queue absent. |
| Phase 1 homepage/navigation/responsive layout | PASS (static review only) | Existing files preserved; no browser/device visual regression run in this environment. |

## Release recommendation
**Do not label the backend activated or production-ready yet.** Apply both migrations to a fresh Supabase project, run `VALIDATION_QUERIES.sql`, configure Auth redirects and storage, then execute the two-account test plan. Resolve the outstanding update-column authorization findings and implement the missing workflows before public production launch.
