# ZELQENTRA B2B — Supabase Activation Guide (Phase 2.2)

This guide uses the existing ZELQENTRA B2B static HTML/CSS/vanilla-JavaScript project. It does not create a new app or change frameworks. Follow the steps in a browser on Android; enable **Desktop site** in Chrome if the Supabase dashboard hides menu items.

> **Current status:** this package is activation-ready for a fresh Supabase project, but it is not connected until you configure your own Project URL/key and apply all three migrations. Do not send credentials to ChatGPT or anyone else.

## 1. Create a Supabase project

1. Open the official Supabase dashboard: https://supabase.com/dashboard.
2. Sign in and choose **New project**.
3. Select the existing Supabase project `nexvora-b2b` (its slug is a legacy technical identifier and is intentionally retained after the public brand change). Do not create a replacement project for this rebrand.
4. Save the database password in a password manager. It is not the browser key and must never be placed in JavaScript.
5. Wait until the project status is ready.

## 2. Copy the browser-safe project configuration

1. In the Supabase project dashboard, open **Project Settings → API** (menu wording may vary).
2. Copy the **Project URL**. It looks like `https://<project-ref>.supabase.co`.
3. Copy a **Publishable key** (`sb_publishable_...`) or, if the dashboard only shows legacy keys, the **anon** key.
4. Do not copy `service_role`, `sb_secret_...`, database password, or any other secret.
5. Open the project's `supabase-config.js` in a text editor and set the two values below. Keep the property name `anonKey` exactly as shown; it accepts either publishable or legacy anon key.

```js
window.NEXVORA_SUPABASE = {
  url: "https://YOUR_PROJECT_REF.supabase.co",
  anonKey: "YOUR_PUBLISHABLE_OR_LEGACY_ANON_KEY"
};
```

The publishable/anon key is intentionally used by browser apps and will be visible to visitors. Security must come from RLS, grants and database policies—not from hiding this key. `supabase-config.js` is listed in `.gitignore`; do not commit your real project values to a public GitHub repository. For static hosting, upload the configured file through the host's private deployment workflow or generate it during deployment. Never place secret keys in it.

### Android editing tip

In Chrome, use **Desktop site** for GitHub or your hosting dashboard. If editing a downloaded project, use a plain-text/code editor app and edit only `supabase-config.js`. Do not use a word processor, which may change quotes or punctuation. Keep a backup of the original ZIP.

## 3. Apply all migrations in the required order

This sequence is for a **new/empty Supabase project**. In Supabase, open **SQL Editor → New query**. For each file below, open the project file, copy its entire contents, paste into SQL Editor, and press **Run**. Wait for a success result before moving to the next migration.

1. `supabase/migrations/202611020001_initial_schema.sql`
   - Creates the 15 application tables, enums, foreign keys, constraints, indexes, Auth profile trigger, initial RLS policies, categories and private Storage bucket.
2. `supabase/migrations/202611020002_phase21_public_directory_hardening.sql`
   - Removes broad public reads from the full company table and creates the limited `public_company_directory` view.
3. `supabase/migrations/202611020003_phase22_authorization_hardening.sql`
   - Restricts company membership mutation, adds the atomic `create_company_workspace` RPC, narrows writable columns, hardens quotation status transitions, message immutability, RFQ/product creation and private document upload paths.

**Do not run migration 001 twice.** It is a first-install migration and is not fully idempotent. Migrations 002 and 003 are patches, but do not rerun any migration blindly after a partial failure. If SQL Editor reports an error, stop, copy the exact error text (remove project identifiers and any private data), and inspect the migration state before retrying. Do not delete a database containing real data to make a migration pass.

## 4. Run database validation

1. Open `supabase/VALIDATION_QUERIES.sql` in the project.
2. Copy and run each numbered query (or run the whole file if the SQL Editor accepts the complete script).
3. Check the results:
   - Query 1 should list exactly 15 application tables.
   - Query 3 should show `rls_enabled = true` for all 15 tables.
   - Queries 6 and 7 should return no rows after users have registered (no missing/orphan profiles).
   - Query 8 should show `company-verification`, `public = false`, a 10 MB limit and PDF/JPEG/PNG allowlist.
   - Query 9 should show only `id`, `display_name`, `country_code`, `industry`, and `logo_path`.
   - Queries 11–15 help inspect Phase 2.2 function grants, column grants, storage policies and view definition.
4. Do not treat a query result as a security certification. The account-to-account tests in `TEST_PLAN.md` are still required.

## 5. Configure Authentication

1. Open **Authentication → Providers** and ensure **Email** is enabled.
2. Decide whether email confirmation is required. For launch, keep it enabled and configure reliable SMTP/email delivery. The built-in test mail service may be rate-limited.
3. Open **Authentication → URL Configuration**.
4. Set **Site URL** to the actual HTTPS website origin (for example, your deployed ZELQENTRA domain).
5. Add the exact allowed Redirect URLs for the deployed website and any local test origin. Example patterns: `http://localhost:8000/**` and `https://YOUR_REAL_DOMAIN/**`. Replace placeholders with the actual host; do not use an unrelated example domain.
6. The password reset email redirects to the current website page. The redirect origin/path must be allowlisted. The project currently sends reset email but does not yet include a complete in-app password-change screen after the link opens.

### Company workspace after email confirmation

Signup saves the chosen company name in the user's Auth metadata. If Supabase immediately returns a session, the app calls `create_company_workspace`. If confirmation is required, the first confirmed login calls the same RPC. The RPC creates the company and its initial owner membership atomically and is idempotent for users who already belong to a company. It does not allow the browser to choose the owner user ID or membership role.

## 6. Confirm Storage

1. Open **Storage → Buckets**.
2. Confirm the `company-verification` bucket exists and is **private**.
3. Confirm the maximum file size is 10 MB and accepted MIME types are PDF, JPEG and PNG.
4. Migration 003 restricts upload paths to `<authenticated-user-id>/<company-id>/<file>` and checks company-manager membership. Do not change the bucket to public.

The browser checks MIME and file size, but this is not malware scanning or file-signature validation. Production still needs server-side file inspection, audit logging and a document review workflow.

## 7. Test the website connection

The page must be served over HTTP(S); do not open `index.html` with `file://`.

- Deploy the static project to your existing host after safely providing `supabase-config.js`, or
- Run a local HTTP server from a computer with the project files:

```bash
python -m http.server 8000
```

Then open `http://localhost:8000` and refresh the page. On the homepage, check the backend badge:

- `DEMO MODE · SAMPLE DATA` — no Supabase configuration is loaded; sample listings are being shown.
- `CONNECTING · SUPABASE DATABASE` — configuration exists and the live marketplace request is in progress.
- `LIVE DATABASE · SUPABASE CONNECTED` — the live product query succeeded. If there are no listings, the page says `0 PUBLISHED LISTINGS`; it does not substitute demo cards.
- `BACKEND ERROR · PREVIEW ONLY` — configuration exists but a live query failed. The error state explicitly says the displayed cards are not live data.

If the badge shows an error, verify the Project URL/key, migration order, browser network, and RLS. Never “fix” an RLS error by making private tables public.

## 8. Create the platform administrator safely

1. Register a separate account using the intended administrator email.
2. Confirm the email and log in once so the Auth profile is created.
3. In Supabase **SQL Editor**, a trusted project owner can promote that exact account. Replace the email with the correct one:

```sql
update public.users
set role = 'platform_admin'
where email = 'admin-address-you-control@example.com';
```

4. Verify exactly one row was updated. Keep the admin account separate from Buyer A and Supplier B. Never add an admin role option to public signup. Never expose the database password or service-role/secret key.

## 9. What remains incomplete

- No live Supabase project was available during this code audit; migrations, Auth, Storage and RLS have **not** been executed against a real database here.
- Buyer/supplier dashboard pages, full product CRUD UI, product image gallery/upload UI, RFQ composer, quotation submission/comparison UI, admin moderation screens, member invitations, protected route system and password-reset completion screen are not implemented.
- Pagination UI and scalable server-side marketplace search are not implemented; current public marketplace fetch is capped at 60 rows and filters those rows in the browser.
- File signature inspection, malware scanning and verification review workflow need a trusted server-side implementation.

Do not label ZELQENTRA production-ready until migration diagnostics, Auth, real marketplace queries, Storage, and direct cross-account RLS tests have all passed. Never send credentials or keys to ChatGPT. If asking for help, share only redacted error messages and non-sensitive validation results.

## Phase 2 database extension

Phase 2 adds an additive migration at `supabase/migrations/202611040001_phase2_core.sql`. It is not run by the frontend or deployment. Read `SUPABASE_PHASE2_SETUP.md` and inspect existing Storage policies before applying it manually. The workspace depends on the new invitation, buyer-request/RFQ, quotation revision/history, notification and moderation RPCs defined there.
