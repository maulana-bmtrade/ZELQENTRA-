# ZELQENTRA Phase 1.2 — Test Report

**Source of truth:** `ZELQENTRA_PHASE1_1_DOMAIN_INTEGRATION_V1.1.zip`  
**Target:** GitHub Pages, apex domain `zalqentra.biz.id`  
**Publishing model selected:** branch root (static/no-build)

## Results

| Test | Status | Evidence / limitation |
|---|---|---|
| ZIP integrity (input) | PASS | Input ZIP opened and `testzip()` returned no corrupt member. |
| ZIP integrity (output) | PASS | Output ZIP re-opened and `testzip()` returned no corrupt member. |
| HTML parsing | PASS | All three HTML files parsed with Python's HTMLParser; structural checks below. Formal Nu HTML5 validator not run. |
| JavaScript syntax | PASS | `node --check app.js` and `node --check backend.js`. |
| CSS parsing | PASS | `styles.css` and `legal.css` parsed with tinycss2; no parse errors. |
| JSON validation | PASS | `manifest.webmanifest` parsed successfully as JSON. JavaScript configuration files were syntax-audited as JavaScript, not treated as JSON. |
| Asset references | PASS | Local HTML `src`/`href`, manifest icon, CSS URLs, and expected root resources resolve. |
| Internal links | PASS | Local page links and in-page fragments resolve against available IDs. |
| CNAME validation | PASS | Root `CNAME` contains exactly `zalqentra.biz.id`. |
| GitHub Actions workflow validation | NOT TESTED | No workflow was added; branch publishing is selected. |
| SEO metadata | PASS | Canonical, OG URL/image, Twitter metadata, sitemap, and robots references consistently use `https://zalqentra.biz.id`. |
| Security scan | PASS (static scan only) | No `sb_secret_*` value, service-role credential assignment, private key block, AWS access key, or GitHub PAT pattern detected. Public Supabase Publishable Key is intentionally retained. |
| Supabase configuration audit | PASS (source audit) | Existing Project URL and Publishable Key unchanged; auth redirect uses `window.location.origin`. Live dashboard settings not verified. |
| Database migration regression | PASS | All migration SQL and validation query bytes match Phase 1.1 source. |
| Mobile responsiveness | BLOCKED | No real browser/device viewport testing in this run. Existing responsive CSS retained. |
| Desktop responsiveness | BLOCKED | No real browser testing in this run. |
| Live asset loading | BLOCKED | Domain not confirmed deployed; no HTTP requests against production performed. |
| DNS propagation | BLOCKED | No DNS records changed or authoritative DNS lookup verified. |
| HTTPS/SSL | BLOCKED | No GitHub Pages certificate or live TLS endpoint verified. |
| Supabase signup/login/recovery/logout | BLOCKED | Requires deployed origin and live Supabase dashboard configuration/testing. |
| Production deployment | BLOCKED | No connected repository was found in the GitHub integration; owner/repository/default branch are unknown. |

## Security notes

- `supabase-config.js` contains a Supabase Project URL and browser-safe Publishable Key. These are intended to be public in a browser application, but public exposure means RLS, grants, and server-side authorization must be correct. This static source scan does not prove RLS effectiveness.
- No Supabase Secret Key or `service_role` credential was detected in the source scan.
- The repository should be treated as public if using GitHub Free Pages. Do not commit private operational documents or credentials in future updates.
- The site contains public contact email/WhatsApp details in its footer and legal pages; this is existing intended public contact information, not an authentication secret.

## Scope and regression protection

- No application HTML/CSS/JS or asset file was modified in Phase 1.2.
- No Supabase config, SQL migration, RLS policy, database function, trigger, schema, or business logic was changed.
- Only `CNAME`, `.nojekyll`, and Phase 1.2 deployment documentation were added.

## Definition of Done

**Source preparation: COMPLETE.**  
**GitHub Pages deployment and custom-domain activation: NOT COMPLETE / BLOCKED** until a repository is selected, Pages is enabled, DNS is configured, and HTTPS/live browser/Auth checks pass.
