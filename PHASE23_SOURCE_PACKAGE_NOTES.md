# NEXVORA B2B — Phase 2.3 Source Package Notes

> **Historical identity notice (3 November 2026):** This engineering record was created when the platform used the working brand name **NEXVORA B2B**. The current public brand is **ZELQENTRA**. This historical record is retained to preserve technical provenance; references such as `NEXVORA_SUPABASE`, `window.NEXVORA`, `nexvora_admin_overview`, and the Supabase project slug `nexvora-b2b` are legacy technical identifiers and are intentionally not renamed in this rebranding release.

## Package provenance
This source package preserves the complete application source from the supplied `NEXVORA_B2B_Phase2.2_Supabase_Activation_Readiness.zip` and overlays the latest Phase A setup guide, test plan, and README available in the Phase 2.3 audited workspace. It includes the Phase 2.3 Phase A static audit report.

## Important Phase 2.3 boundary
Phase 2.3 has completed **Phase A repository audit only**. No application source code or SQL migration was changed during that audit. No Supabase credentials were supplied, no connection was attempted, no SQL was executed, and no database state was changed. Therefore this package must not be interpreted as proof that Supabase is connected or that migrations, Auth, RLS, Storage, or real database workflows have passed.

## Included source
- Existing Phase 1.0 frontend: `index.html`, `styles.css`, `app.js`, `assets/nexvora-mark.svg`.
- Supabase client integration: `backend.js`.
- Browser-safe configuration placeholder and example: `supabase-config.js`, `supabase-config.example.js`.
- Three ordered migrations: `supabase/migrations/202611020001_initial_schema.sql`, `202611020002_phase21_public_directory_hardening.sql`, `202611020003_phase22_authorization_hardening.sql`.
- Database validation queries: `supabase/VALIDATION_QUERIES.sql`.
- Setup, test, project brief, and Phase 2.0–2.3 audit documentation.

## Dependencies
This is a static HTML/CSS/vanilla JavaScript project. It has no npm package manifest, bundler, build step, or local `node_modules` dependency. `backend.js` imports Supabase JS v2 from `https://esm.sh/@supabase/supabase-js@2` at runtime, so the browser needs network access to that CDN. A modern browser and a static HTTP server/hosting provider are required. Do not open via `file://` if module/CORS behavior prevents loading; use a local HTTP server or the deployment host.

## Configuration and secrets
`supabase-config.js` is intentionally a placeholder. Set only the Supabase Project URL and browser-safe publishable key (or legacy anon key) locally. Never put a Supabase secret key, `service_role` key, or database password in browser code, this archive, or a public Git repository. `.gitignore` excludes the local config file.

## Migration safety
The three migrations are ordered and intended for a new/empty project, applied once in sequence. They are not declared safe for blind re-execution. Before applying them to any existing project, inspect migration history and current schema. Do not reset, drop, or overwrite data without explicit owner approval.

## Verification performed for this package
- `node --check app.js`
- `node --check backend.js`
- ZIP integrity check (`unzip -t`)
- Required file inventory check

These are static/package checks only. They do not validate PostgreSQL execution, PostgREST relationships, Supabase Auth, RLS behavior, Storage access, or end-to-end application flows.
