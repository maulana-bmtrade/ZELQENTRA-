# ZELQENTRA Phase 1.2.3

- Uses the V1.2 GitHub Pages source as the baseline.
- Selectively merges the V1.2.2 read-only Supabase diagnostic stages and error metadata.
- Hardens transport diagnostics: metadata-only for the configured project's PostgREST `/rest/v1/` requests.
- Removes response-body capture entirely; no query strings, API key values, access tokens, refresh tokens, or Authorization values are recorded.
- Auth, Storage, and Edge Function traffic is excluded from transport instrumentation.
- No SQL migrations, database schema/data, RLS policies, Supabase project settings, DNS/domain settings, credentials, HTML, CSS, app.js, or brand assets changed.
