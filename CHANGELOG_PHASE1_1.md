# ZELQENTRA — Phase 1.1 Changelog

**Release:** Phase 1.1 — Domain & Brand Integration  
**Brand:** ZELQENTRA  
**Canonical origin:** `https://zalqentra.biz.id`  
**Source baseline:** `ZELQENTRA_PHASE1_READINESS_AUDIT_V1.0.zip`

## Changes

- Added an absolute canonical URL to the homepage and both public legal pages.
- Added absolute Open Graph URL/image metadata and Twitter Card metadata to all three HTML pages.
- Updated homepage Organization structured data with the canonical website URL and absolute logo URL.
- Added absolute Open Graph image dimensions to the homepage.
- Updated the PWA manifest to use root-relative application identity, start URL and scope.
- Added `robots.txt` and `sitemap.xml` for the canonical domain.
- Updated Supabase sign-up confirmation and password-recovery redirect targets to the root of the current serving origin. On production at the canonical host this resolves to `https://zalqentra.biz.id/`; local development remains on its local origin.
- Updated public legal-page display titles/copy from “ZELQENTRA B2B” to “ZELQENTRA”; no legal operator identity was invented.
- Added `DOMAIN_CONFIGURATION_GUIDE.md` and `PHASE1_1_TEST_REPORT.md`.

## Files changed

- `index.html`
- `privacy.html`
- `terms.html`
- `manifest.webmanifest`
- `backend.js`

## Files added

- `robots.txt`
- `sitemap.xml`
- `CHANGELOG_PHASE1_1.md`
- `DOMAIN_CONFIGURATION_GUIDE.md`
- `PHASE1_1_TEST_REPORT.md`

## Intentionally unchanged

- `supabase-config.js` and `supabase-config.example.js` (project URL and browser-safe key are unchanged).
- All SQL migrations and `supabase/VALIDATION_QUERIES.sql`.
- Database schema, RLS, triggers, RPCs, API contracts, legacy JS globals, business logic beyond redirect target options, CSS, SVG brand assets and frontend architecture.
- Hosting/DNS records and Supabase Dashboard settings; these require external account access and owner action.

## Compatibility notes

- Brand spelling is `ZELQENTRA`; canonical domain spelling is `zalqentra.biz.id` (with “a”).
- No `www` hostname is assumed or configured.
- The app uses the homepage as the Supabase email confirmation and password recovery return target. The Supabase client already has `detectSessionInUrl: true`; no separate callback route exists in this source.
- Historical engineering records and legacy identifiers containing `NEXVORA` are retained for provenance and compatibility; they are not public brand copy.
