# NEXVORA B2B — Phase 2.3 B.1 Deployment Configuration Report

> **Historical identity notice (3 November 2026):** This engineering record was created when the platform used the working brand name **NEXVORA B2B**. The current public brand is **ZELQENTRA**. This historical record is retained to preserve technical provenance; references such as `NEXVORA_SUPABASE`, `window.NEXVORA`, `nexvora_admin_overview`, and the Supabase project slug `nexvora-b2b` are legacy technical identifiers and are intentionally not renamed in this rebranding release.

**Scope:** deployment configuration audit only.  
**Source:** user-provided `nexvora-phase2.3-.zip`.  
**Database actions:** none. No SQL was executed.  
**Framework/UI:** unchanged.

## Summary

The deployment blocker was `.gitignore`: it explicitly ignored `supabase-config.js`. A Git-based deployment that builds from the repository could therefore omit the browser configuration file, even though `backend.js` imports it. The ignore rule has been removed. The local `supabase-config.js` is retained and included in this source package.

The configured file contains the project URL and a Supabase `sb_publishable_...` key. Publishable keys are intended for browser use and are not secret credentials. Authorization must still be enforced by RLS, grants, and server-side controls. No Secret Key (`sb_secret_...`) or `service_role` credential is configured or included as a credential.

## Files changed

### 1. `.gitignore`
- Removed the `supabase-config.js` ignore entry.
- Kept `.env`, `.env.*`, `node_modules/`, and `.DS_Store` ignored.
- Added comments clarifying that the deployable browser config may contain only a Project URL and browser-safe Publishable/legacy anon key.
- Result: `supabase-config.js` can be committed and included by Git-based static hosting deployments.

### 2. `supabase-config.example.js`
- Kept `window.NEXVORA_SUPABASE` and the property name `anonKey`.
- Replaced the embedded publishable key with a placeholder.
- Corrected the example URL to the project root (without `/rest/v1/`).
- The actual configured `supabase-config.js` remains untouched.

### 3. `PHASE23_PHASE_B1_DEPLOYMENT_REPORT.md`
- Added this report documenting the audit, change set, deployment behavior, security findings, and validation limits.

## Configuration compatibility

`backend.js` imports `./supabase-config.js` and reads:

- `window.NEXVORA_SUPABASE.url`
- `window.NEXVORA_SUPABASE.anonKey`

The configured file preserves exactly that global object and property naming. The existing Project URL is retained. The publishable key remains in the local deployable configuration file.

## Script loading order

The existing `index.html` order is preserved:

1. `<script src="app.js"></script>`
2. `<script type="module" src="backend.js"></script>`

Both are located at the end of the document body. The classic `app.js` executes first. The module `backend.js` is deferred by browser module semantics, imports the configuration file, initializes the Supabase client, and then performs its live marketplace request. This order is compatible with the current code because the DOM is already parsed and `backend.js` attaches capture-phase handlers for the existing form controls.

The initial frontend render can briefly show the pre-existing sample cards before the backend module changes the status to CONNECTING and replaces the marketplace content. This Phase B.1 task intentionally does not alter UI or frontend behavior.

## Credential and repository scan

Static scan of text files in the supplied source archive found:
- No `sb_secret_...` key value.
- No private-key PEM block.
- No JWT-shaped credential.
- No hard-coded password assignment matching the scan pattern.
- References to `service_role` occur only in warnings/documentation/comments, not as a configured credential.
- The configured Supabase key uses the `sb_publishable_` prefix.

A Publishable key is public by design; it is not a Secret Key. It will be visible in browser source/network traffic and may be present in a public repository. This is acceptable only when database RLS and grants are correctly configured. Do not put `sb_secret_...`, `service_role`, database passwords, SMTP credentials, or other server secrets in this project.

## Deployment instructions

For Git-based Cloudflare Pages or another static host:
1. Ensure `supabase-config.js` is committed to the deployment branch (it is no longer ignored).
2. Confirm the deployed artifact contains `/supabase-config.js` at the same project root as `index.html` and `backend.js`.
3. Deploy normally; no build step is required for this static project.
4. Open the deployed site and inspect the browser Network panel for a successful `supabase-config.js` response.
5. Check the backend badge. `LIVE DATABASE` must only appear after the live product query succeeds. Configuration presence alone is not proof of a live database.

If a separate deployment pipeline generates files, ensure it does not exclude `supabase-config.js`. Do not use a secret variable for a browser publishable key; it is designed to be public. Never inject a Supabase Secret/service-role key into the static bundle.

## Validation results

| Check | Result |
|---|---|
| `.gitignore` no longer excludes `supabase-config.js` | PASS |
| Local configured `supabase-config.js` preserved | PASS |
| `window.NEXVORA_SUPABASE` preserved | PASS |
| `anonKey` property preserved | PASS |
| Example config contains placeholder, not actual key | PASS |
| `backend.js` import/path and property names match | PASS |
| Existing `index.html` script order inspected and preserved | PASS |
| Migration SQL files unchanged | PASS — hash comparison |
| `app.js`, `backend.js`, HTML/CSS unchanged | PASS — hash comparison |
| No Secret/service-role credential detected in source scan | PASS — static scan |
| Supabase network connection / Auth / database query | BLOCKED — not tested in this task |
| GitHub/Cloudflare deployment artifact | BLOCKED — no repository/hosting access used |

## Explicit non-actions

- No SQL Editor or database migration was run.
- No migration SQL was changed.
- No frontend design or feature was changed.
- No backend service code was changed.
- No new dependency or framework was added.
- No database reset or data deletion was performed.

**Conclusion:** deployment packaging is now configured so the existing browser-safe Supabase config file is no longer excluded by `.gitignore`. This is deployment-readiness only; it does not prove the deployed site has been updated or that Supabase connectivity is live.
