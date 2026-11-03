# ZELQENTRA — Complete Source File Inventory

**Baseline:** user-supplied `NEXVORA_B2B_Phase2.3_B3_Business_Identity_Readiness.zip`.
**Audit date:** 3 November 2026.

## Scope

All 28 files in the supplied ZIP were enumerated and inspected. The resulting project contains 41 files. HTML, CSS, JavaScript, SQL, SVG, JSON, webmanifest and Markdown files were scanned for brand references, metadata and asset references.

## Baseline files inspected

- `.gitignore`
- `BACKEND_SETUP.md`
- `PHASE21_AUDIT.md`
- `PHASE22_AUDIT.md`
- `PHASE23_PHASE_A_REPOSITORY_AUDIT.md`
- `PHASE23_PHASE_B1_DEPLOYMENT_REPORT.md`
- `PHASE23_PHASE_B2_CONNECTION_REPORT.md`
- `PHASE23_PHASE_B3_READINESS_REPORT.md`
- `PHASE23_PHASE_B_CONFIGURATION_REPORT.md`
- `PHASE23_SOURCE_PACKAGE_NOTES.md`
- `PHASE2_AUDIT.md`
- `PROJECT_BRIEF.md`
- `README.md`
- `TEST_PLAN.md`
- `app.js`
- `assets/nexvora-mark.svg`
- `backend.js`
- `index.html`
- `legal.css`
- `privacy.html`
- `styles.css`
- `supabase-config.example.js`
- `supabase-config.js`
- `supabase/VALIDATION_QUERIES.sql`
- `supabase/migrations/202611020001_initial_schema.sql`
- `supabase/migrations/202611020002_phase21_public_directory_hardening.sql`
- `supabase/migrations/202611020003_phase22_authorization_hardening.sql`
- `terms.html`

## Current project files after controlled rebrand

- `.gitignore` — **UNCHANGED**
- `BACKEND_SETUP.md` — **MODIFIED**
- `BRAND_FILE_INVENTORY.md` — **ADDED**
- `BRAND_IDENTITY_GUIDELINES.md` — **ADDED**
- `BRAND_NAME_RESEARCH.md` — **ADDED**
- `BRAND_REBRANDING_QA.md` — **ADDED**
- `BRAND_REBRANDING_REPORT.md` — **ADDED**
- `PHASE21_AUDIT.md` — **MODIFIED**
- `PHASE22_AUDIT.md` — **MODIFIED**
- `PHASE23_PHASE_A_REPOSITORY_AUDIT.md` — **MODIFIED**
- `PHASE23_PHASE_B1_DEPLOYMENT_REPORT.md` — **MODIFIED**
- `PHASE23_PHASE_B2_CONNECTION_REPORT.md` — **MODIFIED**
- `PHASE23_PHASE_B3_READINESS_REPORT.md` — **MODIFIED**
- `PHASE23_PHASE_B_CONFIGURATION_REPORT.md` — **MODIFIED**
- `PHASE23_SOURCE_PACKAGE_NOTES.md` — **MODIFIED**
- `PHASE2_AUDIT.md` — **MODIFIED**
- `PROJECT_BRIEF.md` — **MODIFIED**
- `README.md` — **MODIFIED**
- `TEST_PLAN.md` — **MODIFIED**
- `app.js` — **MODIFIED**
- `assets/favicon.svg` — **ADDED**
- `assets/zelqentra-app-icon.svg` — **ADDED**
- `assets/zelqentra-logo-reversed.svg` — **ADDED**
- `assets/zelqentra-logo.svg` — **ADDED**
- `assets/zelqentra-monochrome-white.svg` — **ADDED**
- `assets/zelqentra-monochrome.svg` — **ADDED**
- `assets/zelqentra-social.svg` — **ADDED**
- `assets/zelqentra-symbol.svg` — **ADDED**
- `backend.js` — **MODIFIED**
- `index.html` — **MODIFIED**
- `legal.css` — **MODIFIED**
- `manifest.webmanifest` — **ADDED**
- `privacy.html` — **MODIFIED**
- `styles.css` — **MODIFIED**
- `supabase-config.example.js` — **UNCHANGED**
- `supabase-config.js` — **MODIFIED**
- `supabase/VALIDATION_QUERIES.sql` — **UNCHANGED**
- `supabase/migrations/202611020001_initial_schema.sql` — **UNCHANGED**
- `supabase/migrations/202611020002_phase21_public_directory_hardening.sql` — **UNCHANGED**
- `supabase/migrations/202611020003_phase22_authorization_hardening.sql` — **UNCHANGED**
- `terms.html` — **MODIFIED**

## Identity findings

- Public brand occurrences in the homepage, legal pages, header/footer, marketplace labels, modal copy and current operational documentation were changed to ZELQENTRA.
- The former public logo asset `assets/nexvora-mark.svg` was removed after live references were migrated to the new asset family.
- Historical engineering reports retain original brand references and include a visible historical identity notice.
- Technical identifiers including `window.NEXVORA`, `window.NEXVORA_SUPABASE`, `window.NEXVORA_API`, `__nexvora*`, `nexvora_admin_overview` and Supabase project slug `nexvora-b2b` are intentionally retained.
- Demo supplier name `NexSense Systems` is sample business content, not the platform brand, and was not changed.
- Operator email and WhatsApp details were not changed because no replacement contact channel was supplied.
- No separate dashboard, admin-panel, notification, RFQ-comparison or product-detail UI files exist in this supplied archive; these surfaces were not invented or rebuilt.

## Files deliberately protected

- `supabase/migrations/202611020001_initial_schema.sql`
- `supabase/migrations/202611020002_phase21_public_directory_hardening.sql`
- `supabase/migrations/202611020003_phase22_authorization_hardening.sql`
- `supabase/VALIDATION_QUERIES.sql`
- `.gitignore`
- `supabase-config.example.js`

These files are byte-for-byte unchanged. `supabase-config.js` received a comment-only clarification; its URL and anonKey values remain unchanged.

## Current public identity touchpoints

- `index.html`, `privacy.html`, `terms.html`
- `styles.css`, `legal.css`
- `app.js`, `backend.js` (display strings only)
- `assets/zelqentra-*`, `assets/favicon.svg`
- `manifest.webmanifest`
- `README.md`, `PROJECT_BRIEF.md`, `BACKEND_SETUP.md`, `TEST_PLAN.md`
- `BRAND_NAME_RESEARCH.md`, `BRAND_IDENTITY_GUIDELINES.md`, `BRAND_REBRANDING_REPORT.md`, `BRAND_REBRANDING_QA.md`