# NEXVORA B2B — Phase 2.3 B.2 Connection Verification Report

> **Historical identity notice (3 November 2026):** This engineering record was created when the platform used the working brand name **NEXVORA B2B**. The current public brand is **ZELQENTRA**. This historical record is retained to preserve technical provenance; references such as `NEXVORA_SUPABASE`, `window.NEXVORA`, `nexvora_admin_overview`, and the Supabase project slug `nexvora-b2b` are legacy technical identifiers and are intentionally not renamed in this rebranding release.

**Scope:** read-only Supabase connection verification and frontend/backend startup hardening.  
**Base package:** Phase B.1 deployment ZIP supplied in this conversation.  
**Supabase project URL:** `https://vtlywagosbudjedcfudv.supabase.co`  
**Database changes:** none. No SQL or migration was executed. No INSERT, UPDATE, or DELETE was issued.

## Executive result

- Configuration file was found and inspected.
- `window.NEXVORA_SUPABASE` and the `url` / `anonKey` property names are preserved.
- The configured key is non-empty and has the expected browser Publishable Key prefix. Its value is intentionally not reproduced in this report.
- Frontend startup was hardened to avoid briefly showing demo products when Supabase configuration is present.
- `LIVE DATABASE` is only set after successful read-only database requests.
- **Real connection verification: BLOCKED.** The verification runtime could not resolve the Supabase hostname (`curl` returned HTTP `000`, DNS resolution error). This means the request did not reach Supabase; it does not prove the Supabase project is down or the key is invalid. The site was not available as a deployed browser session for an end-to-end check.

## Files changed

### `index.html`
- Loads `supabase-config.js` as a classic script before `app.js`.
- Keeps the existing `app.js` and module `backend.js` integration.
- This makes `window.NEXVORA_SUPABASE` available to the legacy frontend before its initial render.

### `app.js`
- When valid public Supabase configuration is present, shows a connecting state instead of rendering sample marketplace cards.
- Adds a startup watchdog. If the backend module does not initialize within 20 seconds, the interface changes to a backend error state rather than silently falling back to demo listings.
- Prevents the legacy demo search/filter handlers from replacing live marketplace results after backend configuration is detected.
- When no Supabase configuration is present, the original demo mode remains available.

### `backend.js`
- Uses the already-loaded global configuration; removed the redundant module import of `supabase-config.js`.
- Validates that URL and `anonKey` are present before creating the Supabase client.
- Adds a read-only connectivity probe against `products` using `SELECT id` with `HEAD` and `LIMIT 1`.
- Continues with the published-products read and, when needed, the `public_company_directory` read.
- Sets `LIVE DATABASE` only after the read-only probe and required marketplace reads succeed.
- On failure, sets `BACKEND ERROR`, does not substitute demo products, and shows a sanitized diagnostic category. Detailed technical errors remain in the browser console for developer troubleshooting.
- Fixes the “Explore all products” action so it does not restore sample cards while the backend is configured.

## Configuration audit

- `supabase-config.js` exists in the project and is included in the ZIP.
- Global object: `window.NEXVORA_SUPABASE`.
- Properties: `url` and `anonKey`.
- Project URL matches the requested project.
- Publishable Key: present, non-empty, and prefix-checked. **The key value is not printed here.**
- No Secret Key or `service_role` credential was added by this phase.
- `.gitignore` does not ignore `supabase-config.js`, so the browser-safe Project URL and Publishable Key can be included in static hosting deployment. `.env` files remain ignored.
- `supabase-config.example.js` contains a placeholder only.

A Supabase Publishable Key is designed for browser use. It is not a substitute for RLS. Do not put an `sb_secret_...` or `service_role` credential in any frontend file or public repository.

## Loading order and race-condition review

The page now loads scripts in this order:

1. `supabase-config.js` — classic script, establishes the global configuration.
2. `app.js` — can detect configuration before its initial marketplace render.
3. `backend.js` — ES module, initializes the Supabase client and performs the real read-only database check.

The module remains deferred by browser module semantics. The frontend therefore starts in `CONNECTING` when a complete configuration exists. A watchdog handles a failed/delayed module load. The backend switches to `LIVE DATABASE` only after successful database reads, or to `BACKEND ERROR` on a failed request.

## Read-only connection attempt

Attempted request shape:

`GET /rest/v1/products?select=id&limit=1`

The request was not able to resolve `vtlywagosbudjedcfudv.supabase.co` in the execution environment. Result: **HTTP 000 / DNS resolution failure**. The request did not reach the Supabase API. No data was read or changed by this attempt.

## Test results

| Test | Result | Evidence / notes |
|---|---|---|
| Configuration file exists | PASS | `supabase-config.js` present in supplied package |
| Project URL matches requested project | PASS | Static value comparison |
| `anonKey` property retained | PASS | Static inspection |
| Publishable Key present and expected prefix | PASS | Presence/prefix/length checked without printing value |
| Supabase client initialization code | PASS — static | `createClient` uses `cfg.url` and `cfg.anonKey` |
| Read-only connectivity probe implemented | PASS — static | `products` HEAD/SELECT probe, no write operation |
| `LIVE DATABASE` requires successful query | PASS — static | status is set after probe and marketplace reads |
| Error handling | PASS — static | sanitized UI reason; detailed error only in console |
| Demo fallback suppressed with configured backend | PASS — static | configured path renders connecting/error/live states, not demo cards |
| Race condition / script order | PASS — static | config script precedes app script; backend module follows |
| JavaScript syntax `app.js` | PASS | `node --check app.js` |
| JavaScript module syntax `backend.js` | PASS | `node --input-type=module --check` |
| Migration files unchanged | PASS | SHA-256 comparison against supplied B.1 ZIP |
| ZIP integrity | PASS | archive test completed |
| Actual DNS/API connectivity | BLOCKED | runtime DNS could not resolve project hostname |
| Actual browser deployment check | BLOCKED | no deployed browser session available in this task |
| Actual RLS/data result | BLOCKED | request did not reach Supabase |

## Manual verification after deployment

1. Deploy this ZIP to the existing hosting environment.
2. Open the deployed site in a modern browser.
3. Open Developer Tools → Network and reload.
4. Confirm `supabase-config.js` returns HTTP 200 and `backend.js` loads successfully.
5. Confirm the browser makes a read-only request to `/rest/v1/products` (the `HEAD` probe and subsequent `GET`).
6. If the request succeeds, the status badge should show `LIVE DATABASE`. If there are no published products, it should show `LIVE DATABASE · 0 PUBLISHED LISTINGS` and an empty state—not demo cards.
7. If the request fails, the badge should show `BACKEND ERROR`. Check the browser console and Network response:
   - Network/DNS/CORS: check hosting network access, URL, and browser restrictions.
   - 401/403: check Publishable Key and RLS/select policies.
   - Missing relation/schema-cache response: verify migration state manually; do not rerun migrations blindly.
8. Do not share the Publishable Key in screenshots, logs, or public issue reports unless it is intentionally treated as public browser configuration; never share Secret Key or `service_role`.

## Explicitly not performed

- No SQL Editor actions.
- No migrations executed.
- No database schema changes.
- No authentication signup/login/logout.
- No INSERT, UPDATE, or DELETE.
- No Storage operations.
- No RLS penetration test.
- No production deployment.

**Phase B.2 conclusion:** implementation and static verification are complete; real Supabase connectivity remains **BLOCKED** pending a deployed browser test / network access to the project endpoint. This phase does not claim that the backend is active.
