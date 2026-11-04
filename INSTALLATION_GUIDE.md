# ZELQENTRA installation guide

## Requirements
- Static web hosting with HTTPS.
- Existing Supabase project with migrations `202611020001_initial_schema.sql`, `202611020002_phase21_public_directory_hardening.sql`, and `202611020003_phase22_authorization_hardening.sql` applied in order.
- A Supabase Publishable key (never a Secret/service_role key).

## Configure
1. Open `supabase-config.js`.
2. Set `window.NEXVORA_SUPABASE.url` to your Supabase Project URL.
3. Set `window.NEXVORA_SUPABASE.anonKey` to the Publishable key.
4. Keep the existing key public-safe and ensure RLS is enabled.
5. Do not copy secrets into frontend files.

## Local preview
Serve the extracted directory using any static HTTP server (not `file://`) because browser ES modules and CDN imports require HTTP(S). For example, with Python installed run `python -m http.server 8000` from the project root, then open `http://localhost:8000`.

## Routes
- `/` landing page
- `/marketplace/` public published-product discovery
- `/marketplace/product/?id=<product-uuid>` published product detail
- `/companies/` public company directory
- `/companies/profile.html?id=<company-uuid>` public company profile

## Phase 2 workspace routes

- Company workspace: `/workspace/`
- Platform admin: `/workspace/admin.html` (requires `public.users.role = 'platform_admin'`)

For the new modules to work, review and manually apply `supabase/migrations/202611040001_phase2_core.sql` after confirming the three original migrations are present. Follow `SUPABASE_PHASE2_SETUP.md`; do not expose the conversation attachment bucket publicly. After applying, test with separate buyer/supplier accounts before enabling real operations.
