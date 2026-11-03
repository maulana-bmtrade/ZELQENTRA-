# ZELQENTRA Phase 1.1 — Test Report

**Release:** Phase 1.1 — Domain & Brand Integration  
**Source:** `ZELQENTRA_PHASE1_READINESS_AUDIT_V1.0.zip`  
**Canonical target:** `https://zalqentra.biz.id`

## Summary

Source-level domain integration is implemented. Static checks that could be run locally passed. External deployment, DNS, TLS, browser, and live Supabase checks remain blocked because no hosting/DNS/Supabase dashboard session or deployed target was provided in this task.

## Test matrix

| Test | Result | Evidence / limitation |
|---|---|---|
| ZIP integrity | PASS | Final archive passed `zipfile.testzip()` with no corrupt entries. |
| HTML parsing / local structure | PASS (limited) | All three HTML files parsed with Python HTMLParser; no duplicate IDs; no missing local `src`/`href` references. This is not a full WHATWG validator run. |
| Formal HTML validation | BLOCKED | No Nu HTML Checker/validator execution or browser-based validator available in this environment. |
| JavaScript syntax | PASS | `node --check` passed for `app.js`, `backend.js`, and `supabase-config.js`. |
| CSS validation | PASS (parser) | `tinycss2` parsed `styles.css` and `legal.css` with no parser error tokens. Not a full CSS conformance audit. |
| JSON validation | PASS | `manifest.webmanifest` parsed successfully. |
| Sitemap XML | PASS | `sitemap.xml` parsed successfully with XML parser. |
| SVG validation | PASS (XML) | All SVG assets parsed as XML. This does not validate rendering in target browsers. |
| Canonical URL | PASS | Homepage and both legal pages each have exactly one canonical URL on `https://zalqentra.biz.id`. |
| Metadata | PASS (source) | Absolute OG URL/image, OG title/description, Twitter Card fields, page descriptions, viewport, language and theme color present. |
| Social image dimensions | PASS (source) | `assets/zelqentra-social.svg` declares 1200×630. Social crawler fetch/render not tested. |
| Sitemap / robots | PASS (source) | `robots.txt` points to canonical sitemap; sitemap contains the three public HTML pages. HTTP serving not tested. |
| Asset references | PASS | No missing local references found in the three HTML pages. |
| Internal links | PASS (static) | Local page/asset references resolve within the ZIP. Runtime navigation not browser-tested. |
| Auth redirect audit | PASS (static) | Signup `emailRedirectTo`, reset `redirectTo`, and existing `detectSessionInUrl: true` were inspected. No live email was sent. |
| Supabase dashboard configuration | BLOCKED | Site URL and Allowed Redirect URLs require manual dashboard configuration. |
| Mobile layout | BLOCKED | No deployed browser/device test performed. |
| Desktop layout | BLOCKED | No deployed browser/device test performed. |
| Security regression | PASS (scope-limited) | No SQL, RLS, Supabase config, key, schema, or API contract changes. Static source review only; no penetration test. |
| DNS propagation | BLOCKED | No DNS query was performed and no DNS records were changed. |
| HTTPS / SSL | BLOCKED | Domain certificate and redirect behavior not tested. |
| Mixed content | BLOCKED | Requires loading deployed site in a browser and inspecting console/network. |
| Production test | BLOCKED | Deployment has not been performed or confirmed. |

## Important findings

- The requested spelling is implemented exactly: public brand `ZELQENTRA`, domain `zalqentra.biz.id`.
- No `zelqentra.biz.id` domain typo was found in the public page metadata.
- No `www` hostname is assumed. If the owner enables it, DNS, hosting and Supabase redirect allowlisting must be configured deliberately.
- There is no separate auth callback page in this codebase. Supabase's existing `detectSessionInUrl: true` processes confirmation/recovery redirects on the homepage.
- The application does not currently have dedicated private dashboard routes. The auth interface is a modal on the homepage; no nonexistent private URLs were added to robots/sitemap rules.
- The legal pages still contain pre-launch disclosures. Confirm operator legal identity and obtain legal review before commercial launch.

## Regression protection

- All three SQL migration files and `supabase/VALIDATION_QUERIES.sql` are byte-for-byte unchanged from the source ZIP.
- `supabase-config.js` is byte-for-byte unchanged; Project URL and browser-safe key were not modified.
- No framework, database, RLS, trigger, RPC, CSS, SVG identity asset, or project architecture change was made.

## Release decision

**Phase 1.1 source integration: COMPLETE.**  
**Phase 1.1 deployment readiness: PENDING external configuration and live validation.**

The source is prepared for the canonical domain, but the site must not be described as deployed, DNS-connected, SSL-verified, or Supabase-dashboard-configured until those checks are completed.
