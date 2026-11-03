# CHANGELOG — ZELQENTRA Phase 1.2

## Scope
Prepare the existing static ZELQENTRA site for GitHub Pages branch publishing and its apex custom domain `zalqentra.biz.id`.

## Added
- `CNAME` — GitHub Pages branch-publishing custom-domain declaration.
- `.nojekyll` — prevents Jekyll processing of the static source tree.
- `GITHUB_PAGES_DEPLOYMENT_GUIDE.md` — branch publishing, Android upload, validation, and rollback instructions.
- `DNS_CONFIGURATION_GUIDE.md` — apex A/AAAA records, verification, propagation, HTTPS, and Supabase dashboard steps.
- `PHASE1_2_TEST_REPORT.md` — status of performed checks and external blockers.

## Deliberately not added
- No GitHub Actions workflow: the source is already a static site with no build step; direct branch publishing is the least-complex fit.
- No `www` CNAME: the GitHub account/organization hostname is not known and `www` was not selected as the canonical host.
- No SPA fallback: the project uses static HTML pages and fragment navigation, not client-side route handling.

## Unchanged
- All existing HTML, CSS, JavaScript, assets, and project documentation from Phase 1.1.
- `supabase-config.js` and its Project URL / browser-safe Publishable Key.
- All SQL migrations, validation queries, database schema, RLS policies, functions, and triggers.
- Existing frontend architecture and business logic.

## Deployment status
Source package prepared and statically validated. GitHub repository identity/access was not available in the connected GitHub account, so no repository write, Pages setting, DNS update, or live deployment was performed.
