# ZELQENTRA database migration order

Apply migrations only to the existing Supabase project after taking a backup. Never reset/recreate the database and never disable RLS.

## Required order

1. `202611020001_initial_schema.sql` — initial application schema and baseline RLS.
2. `202611020002_phase21_public_directory_hardening.sql` — public company directory hardening.
3. `202611020003_phase22_authorization_hardening.sql` — column grants, membership and quotation authorization hardening.
4. `202611040001_phase2_core.sql` — additive Phase 2 objects, workflows, storage buckets and triggers.
5. `202611040002_phase2_predeployment_security_fixes.sql` — mandatory security correction: legacy Storage policy cleanup, hardened path policies, protected quotation revision context, fail-soft notifications, self-moderation guard and RFQ/request delete restrictions.

Migrations 4 and 5 are a pair. Apply them consecutively in the same controlled maintenance window before enabling Phase 2 frontend workflows. Migration 4 is fail-closed for quotation commercial revisions until migration 5 installs the protected revision RPC context.

## Safety rules

- Confirm the first three migrations have already been applied to the intended project; do not re-run the baseline on a populated project.
- Review every migration and run a database backup before application.
- Do not apply migrations automatically from the browser.
- Do not expose `service_role` or Supabase Secret keys in frontend code.
- Do not loosen `companies` anonymous access; public company discovery must use `public_company_directory`.
- Run `supabase/PHASE2_VALIDATION_QUERIES.sql` after application and inspect every Storage policy, including policies whose names are not known to this package.
- If the live policy catalog contains any unknown broad policy on `storage.objects`, stop and review it. PostgreSQL permissive policies are OR-combined.

No migration in this package has been executed against Supabase LIVE by the audit process.
