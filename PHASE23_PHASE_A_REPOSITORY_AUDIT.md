# NEXVORA B2B Phase 2.3 — Phase A Repository Audit

> **Historical identity notice (3 November 2026):** This engineering record was created when the platform used the working brand name **NEXVORA B2B**. The current public brand is **ZELQENTRA**. This historical record is retained to preserve technical provenance; references such as `NEXVORA_SUPABASE`, `window.NEXVORA`, `nexvora_admin_overview`, and the Supabase project slug `nexvora-b2b` are legacy technical identifiers and are intentionally not renamed in this rebranding release.

**Audit date:** 2026-11-02  
**Scope:** Static inspection of the latest supplied Phase 2.2 source archive.  
**Supabase target stated by owner:** `nexvora-b2b`, `eu-west-1` (West Europe), Free plan.  
**Execution boundary:** No Supabase credentials, project URL, publishable key, GitHub repository URL, or database access were supplied. No SQL was executed and no database state was changed.

## 1. Source-of-truth and audit method

The working folder available in this session contains only a subset of project files (HTML and documentation). The complete latest source tree was therefore inspected from `NEXVORA_B2B_Phase2.2_Supabase_Activation_Readiness.zip`, which contains the Phase 2.2 project folder and migrations 001–003. No new application or repository was created. Existing application files were not rewritten during Phase A.

The latest supplied source archive contains:

- Static frontend: `index.html`, `styles.css`, `app.js`, SVG brand asset.
- Supabase client integration: `backend.js`, `supabase-config.js`, `supabase-config.example.js`.
- Database migrations: 001 initial schema, 002 Phase 2.1 public directory hardening, 003 Phase 2.2 authorization hardening.
- Diagnostics and documentation: `supabase/VALIDATION_QUERIES.sql`, `BACKEND_SETUP.md`, `TEST_PLAN.md`, prior audit reports.
- No `package.json`, build pipeline, framework configuration, server-side API, or environment-injection build step is present. The application is currently a static HTML/CSS/vanilla JavaScript site using a browser Supabase client.

## 2. Phase A results

| Area | Status | Finding |
|---|---|---|
| Phase 1 frontend files | PASS — static inspection | Homepage, navigation, marketplace section, CSS and brand asset are present. |
| Existing framework | PASS — static inspection | Plain HTML/CSS/vanilla JS; no framework replacement is needed. |
| Supabase client | PASS — static inspection | Supabase JS v2 imported as an ES module from `esm.sh`. |
| Public browser config | BLOCKED | `supabase-config.js` has empty URL/key placeholders. No project URL or publishable key is present. |
| Secret-key exposure | PASS — static inspection | No service-role/secret key found in supplied config. Keep it that way. |
| Database schema | PASS — static inventory | 15 application tables are declared in migration 001. Actual catalog not inspected. |
| Auth profile link | PASS — static inspection | `public.users.id` references `auth.users.id`; an Auth insert trigger creates the public profile. |
| Workspace creation | PASS — static inspection | `create_company_workspace(text)` derives the owner from `auth.uid()` and inserts company + owner membership in one function transaction. |
| RLS | BLOCKED | Policies are present in SQL, but no database execution or cross-account test has occurred. |
| Storage | BLOCKED | Private bucket and policies are declared; actual bucket/policies and upload/download behavior not verified. |
| Marketplace live read | BLOCKED | Code queries `products` and `public_company_directory`; no real Supabase request has been made. |
| RFQ/quotation services | PARTIAL | Service functions exist, but full screens and end-to-end workflow are absent. |
| Documentation | PASS — static inspection | Setup and test guides exist, but they must be updated after real project validation. |

## 3. Static code checks executed

- `node --check app.js` — PASS.
- `node --check backend.js` — PASS.
- ZIP file inventory and extraction — PASS.
- Table/RPC references extracted from `backend.js`:
  - Tables/views: `buyer_requests`, `company_members`, `products`, `public_company_directory`, `quotations`, `rfqs`, `verification_documents`.
  - Storage bucket: `company-verification`.
  - RPCs: `create_company_workspace`, `nexvora_admin_overview`.
- The referenced names are present in the supplied migrations/schema, based on static comparison.

These checks do **not** prove that PostgreSQL accepts the migrations, that grants/RLS work, or that PostgREST relationship resolution succeeds.

## 4. Findings requiring correction or explicit acceptance before activation

### High — frontend can briefly render demo cards before live data loading

`app.js` renders its six hard-coded sample products immediately. `backend.js` is a module and executes after the classic script; when Supabase is configured, the live query replaces the sample cards asynchronously. This creates a short interval where demo cards may appear even in a configured session. Phase B should gate demo rendering until backend mode is known, while preserving demo mode when no configuration exists.

### High — authentication recovery flow is incomplete

`backend.js` contains a password-reset request branch, but the current `index.html` has no visible reset-password action to enter that mode. There is also no recovery callback UI calling `supabase.auth.updateUser({ password })`. Reset completion is therefore NOT IMPLEMENTED.

### High — migration 003 conversation integrity needs another pass

The conversation insert policy verifies `created_by = auth.uid()` and that the caller manages at least one of the two companies. It does not validate that a supplied `rfq_id`, when present, belongs to the same `buyer_company_id` and `supplier_company_id` pair. This is an integrity gap; Phase F should add a database-side consistency check (constraint/trigger or narrowly scoped RPC) before enabling production conversations.

### Medium — migration rerun safety is not established

Migrations 001 and 002/003 contain non-idempotent `CREATE TYPE`, `CREATE TABLE`, and `CREATE POLICY` statements. They are intended to be applied once, in order, to a clean project. Do not paste/run them again if already applied. Before Phase C, check Supabase migration history/catalog and determine whether this newly created project is empty. Do not reset or drop anything to force a clean state.

### Medium — demo cards are not a database fallback, but app startup needs a clearer state gate

On live query failure, `backend.js` replaces the product grid with an error state and does not intentionally substitute sample cards. However, the initial classic-script render described above can flash demo content before the module finishes initializing. The status badge is also created only when `backend.js` successfully executes; a module/CDN import failure may leave the page displaying the original demo UI without a backend status badge.

### Medium — public profile/company data model is only partially integrated

The live product query reads `product_categories(name)` and then separately queries `public_company_directory`. The company view exposes a limited set of fields, which is good for public data minimization. However, the current live product UI only displays company display name/country and does not expose business profiles, verification status, or directory search. These workflows remain incomplete.

### Medium — verification documents are private from anonymous/public access, but company-member scope is broad

The current metadata and Storage read policies allow company members to read verification documents for their company. These are not public reads, but all membership roles may be broader than necessary for sensitive KYC/business documents. Before production, decide whether read access should be limited to owner/admin and platform administrators, then test using a normal member account.

### Medium — client error presentation should be normalized

The live marketplace error state includes the escaped Supabase `error.message`. It is escaped against HTML injection, but raw database/provider messages may be confusing and may reveal schema details. Phase B should show a stable user-facing message and retain detailed diagnostics only in controlled developer logging.

### Low — external module dependency

Supabase JS is loaded from `https://esm.sh/@supabase/supabase-js@2`. This requires the hosting browser to reach that CDN and the hosting CSP to permit it. Confirm this on the target Cloudflare/hosting domain. No package/build setup currently exists for bundling the library locally.

### Low — no environment variable injection mechanism

The project is a static site with no build pipeline. Browser code cannot directly read Cloudflare build secrets as runtime `process.env` values. The current `supabase-config.js` public config pattern is compatible with a static deployment when it contains only Project URL + publishable/anon key. These values are public client configuration; database security must be enforced by RLS. Never place secret/service-role keys there.

## 5. Migration inventory and preliminary review

1. `202611020001_initial_schema.sql` — declares 15 tables, enums, Auth profile trigger, helper functions, indexes, RLS policies, admin metrics RPC, categories and private Storage bucket.
2. `202611020002_phase21_public_directory_hardening.sql` — narrows direct company table reads and adds `public_company_directory` with a limited public column list and indexes.
3. `202611020003_phase22_authorization_hardening.sql` — restricts membership writes, introduces atomic workspace RPC, column-level update grants, quotation status trigger, message/conversation restrictions, Storage path checks and RFQ policies.

The files are ordered consistently by their numeric prefixes. Static review found no evidence that they were executed in the target Supabase project. The migrations are not safe to rerun blindly. No migration is marked applied by this audit.

## 6. Feature readiness

| Feature | Current code state | Real test status |
|---|---|---|
| Homepage/navigation/responsive styling | Present | Browser/device regression not run |
| Demo marketplace | Present in `app.js` | Static only |
| Live published-products read | Present in `backend.js` | BLOCKED — no project URL/key |
| Search/category filter | Client-side over fetched records | BLOCKED — no live dataset |
| Product detail page | Toast preview only | NOT IMPLEMENTED |
| Product create/update/delete service methods | Present | BLOCKED — no Auth/RLS test |
| Product image storage/gallery UI | Not present | NOT IMPLEMENTED |
| Signup/login/logout/session | Partial client wiring | BLOCKED — no Auth project |
| Password reset completion | Not present | NOT IMPLEMENTED |
| Protected pages/role dashboards | Not present | NOT IMPLEMENTED |
| Company workspace RPC | SQL + client call present | BLOCKED — no database execution |
| Buyer request/RFQ/quotation services | Partial service methods | BLOCKED — no live test; UI NOT IMPLEMENTED |
| Conversations/messages/notifications UI | Not present | NOT IMPLEMENTED |
| Admin overview RPC | SQL + client call present | BLOCKED — no admin account |
| Admin moderation UI | Not present | NOT IMPLEMENTED |
| Verification upload helper | Present | BLOCKED — no Storage/RLS test |
| Malware/file-signature scanning | Not present | NOT IMPLEMENTED |

## 7. Required owner action before Phase B/C

The Supabase project name and region are not sufficient to connect the application. Obtain the following locally from the Supabase Dashboard; do not send either value to ChatGPT:

1. Project URL from **Project Settings → API** (or the API/project URL panel).
2. Publishable key (`sb_publishable_...`) from the same API keys area. If the project UI only exposes the legacy anon key, that is the browser-safe alternative.
3. Confirm whether the project is brand-new/empty or whether any SQL has already been run. Do not reset it.

Enter the Project URL and publishable/anon key directly into the local deployment's `supabase-config.js`. The current property name is `anonKey`; the publishable key value can be assigned to this property without renaming the client integration. Do not commit credentials if the repository is public unless the owner explicitly accepts the public client configuration being versioned; safer is to keep a deployment-specific config file out of Git and provide a placeholder example.

Also provide the actual GitHub repository URL/branch if the intended source of truth is a remote repository rather than the supplied Phase 2.2 ZIP. No repository identifier was present in the supplied artifacts or prior project context.

## 8. Phase A decision

**PHASE A — COMPLETE (static repository audit only).**  
**PHASE B — BLOCKED pending local Project URL + publishable/anon key and confirmation of database migration state.**  
**PHASE C onward — NOT STARTED.**

No Supabase connection was attempted, no migration was executed, no data was changed, and no real integration test is claimed as passed.
