# ZELQENTRA — Baseline Architecture & Phase 1 Readiness Audit

**Source of truth audited:** `NEW_BRAND_B2B_COMPLETE_REBRANDING_V1.zip`  
**Audit date:** 2026-11-03  
**Scope:** Full archive inventory, public pages/assets, frontend JavaScript, Supabase browser integration, configuration, migrations, project documentation, static package checks.  
**Change policy:** No framework replacement, no schema/RLS/function/migration edits, no credential changes, no removal of existing modules.

## 1. Executive summary

The supplied ZIP is a small static web application with a Supabase browser-client integration and a PostgreSQL schema foundation. It is **not yet a complete global B2B commerce platform**. It has a functioning visual landing page, a demo catalogue fallback, Supabase Auth integration code, a live published-product read path, legal-information pages, and a browser-side API facade for future workflows. Most of the roadmap exists as schema/API groundwork or concept UI rather than complete end-user journeys.

The source archive is structurally intact. Static JavaScript, CSS, JSON, SVG and local-link checks pass. These checks do not establish live Supabase connectivity, authorization correctness, browser functionality, production security or Core Web Vitals.

**Phase 1 status: PARTIALLY READY / DEPLOYMENT BLOCKED.** The code package can be hosted as a static site, but production metadata and launch checks cannot be completed without the final HTTPS domain, confirmation of official contact/operator details, the live Supabase environment state, and a deployed browser test.

## 2. Current architecture

### Frontend
- Static multi-page site: `index.html`, `privacy.html`, `terms.html`.
- Vanilla JavaScript; no framework, bundler, TypeScript compiler or package manifest.
- `styles.css` contains the main design system and responsive layouts; `legal.css` styles legal pages.
- `app.js` handles sample marketplace rendering/filtering, modal shell, toast messages, mobile navigation and configuration-state bootstrap.
- `backend.js` is an ES module that imports `@supabase/supabase-js@2` from `esm.sh`, creates the Supabase client and implements Auth, live listing reads and a small browser API facade.
- `supabase-config.js` is loaded before `app.js`; it contains the browser-side Supabase configuration. The configured key must remain publishable/anon only.

### Backend and data layer
- Supabase PostgreSQL is the intended persistence layer; there is no separately deployed application server in this archive.
- Three ordered SQL migrations define the base schema and subsequent public-directory/authorization hardening.
- Browser requests use Supabase Auth, PostgREST, RPC and Storage directly. RLS, grants, constraints and trusted database functions are the security boundary; frontend checks are not authoritative.
- Public company data is exposed through `public_company_directory`; private company details are intended to remain protected.

### Deployment model
- Static hosting is compatible with the current source layout.
- The package does not include a build pipeline, automated CI, server-side runtime, environment-specific deployment manifests, automated browser tests or monitoring configuration.
- The final canonical URL and absolute social image URL are not yet defined.

## 3. Existing features (as implemented in source)

| Area | Existing implementation | Actual status |
|---|---|---|
| Brand and landing page | ZELQENTRA logo assets, visual system, homepage sections | Implemented static UI |
| Responsive layout | Desktop/tablet/mobile CSS breakpoints | Implemented; browser verification pending |
| Mobile navigation | Toggle menu with close-on-link behavior | Implemented; accessibility state was incomplete and improved in this release |
| Marketplace fallback | Curated local sample data, search and category filtering | Demo-only; must not be represented as production records |
| Live marketplace read | Published products + public company directory read | Code implemented; live integration unverified |
| Signup/login | Supabase Auth sign-up and password login | Code implemented; live Auth flow unverified |
| Password recovery | `resetPasswordForEmail` call | Code implemented; redirect/configuration and email delivery unverified |
| Session UI | Session lookup and account/sign-out label | Basic implementation; no full account dashboard |
| Company workspace | `create_company_workspace` RPC after account creation/login | Code implemented; RPC/migration behavior unverified against live project |
| Company membership reads | Browser API method for own company memberships | API facade only; no user-facing dashboard |
| Product CRUD | Browser API methods for create/update/delete | API facade only; no complete listing management UI |
| Buyer requests / RFQs | Browser API methods and related schema | Partial API groundwork; not a complete workflow |
| Quotations | Browser API submission method and schema | Partial API groundwork; no quotation management UI |
| Admin overview | RPC call to legacy-named `nexvora_admin_overview` | API facade only; no admin dashboard |
| Verification uploads | PDF/JPEG/PNG client-side precheck and private Storage upload | API facade only; server-side file-content validation and live RLS tests not established |
| Privacy / terms | `privacy.html`, `terms.html` | Preliminary drafts; operator/legal review outstanding |
| AI / trade intelligence | Explanatory landing-page visuals and copy | Concept UI only; no live AI, trade data or analytics engine |

## 4. Incomplete features and functional gaps

1. No complete role-specific dashboards for buyer, supplier, business partner or administrator.
2. No complete company-profile creation/editing UI or company directory search/filter UI.
3. No product publishing workflow UI, product detail page, image management or moderation console.
4. No complete buyer RFQ creation, supplier response, quotation comparison, negotiation, expiry or history workflow.
5. No messaging/conversation UI or notification center.
6. No end-user verification review workflow; upload API method alone is not a verification process.
7. No operational business-matching, AI analysis, demand intelligence, trade monitoring or market data ingestion.
8. No subscription, billing, payment, commercial entitlements or audit-log viewer.
9. No automated unit/integration/browser test suite or CI pipeline.
10. No production deployment evidence, uptime monitoring, error reporting, backup/restore evidence or measured performance report.

## 5. Security findings

### Positive controls present in source
- Frontend config is designed for a browser-safe publishable/anon key; documentation prohibits service-role/secret keys in browser code.
- SQL migrations include RLS, restricted grants, role/ownership helper functions, column-level update restrictions and controlled quotation status transitions.
- Public company directory is a restricted view rather than a direct public read of the full companies table.
- HTML rendering of live product text uses an escaping helper before inserting strings into markup.
- Verification bucket is configured private in the base migration, with path and company-manager checks in the later hardening migration.

### Risks requiring follow-up
- **Critical verification gap:** no live RLS, role-boundary, Storage, Auth or RPC tests have been run against the configured Supabase project. SQL inspection is not proof of deployed policy behavior.
- The browser API methods accept caller-provided objects and spread them into insert/update payloads. Current database grants/RLS are intended to constrain this, but service methods should later use explicit allow-listed field mapping and schema validation to reduce accidental over-posting.
- `createBuyerRequest` performs the buyer-request insert and RFQ insert as two independent browser requests. If the second request fails, the first record can remain without its RFQ. This needs a transaction-safe database RPC or equivalent server-side workflow before the feature is exposed.
- Verification file checks rely on client-supplied MIME type and extension-safe filename handling. File signatures/content inspection and abuse controls are not established by the browser code.
- Supabase JS is loaded from a third-party ESM CDN. There is no visible lockfile, self-hosted bundle, Subresource Integrity policy or Content Security Policy in the package. Supply-chain and CSP strategy should be reviewed before production.
- No rate-limiting implementation or abuse monitoring is visible in this static client package; assess Supabase platform controls and trusted server-side enforcement for sensitive workflows.
- Authentication redirect URLs, email confirmation, password recovery, session edge cases and account enumeration behavior have not been tested in the actual project.
- Public contact details and legal operator identity have not been independently confirmed; do not treat draft legal pages as approved disclosures.

**No confirmed secret exposure was identified in the inspected browser configuration.** The key value itself is intentionally not reproduced in this report. Keep it private from public issue trackers and never add a service-role/secret key to the client.

## 6. Performance and accessibility findings

- Small source footprint and no framework/build runtime reduce baseline client overhead.
- Google Fonts and Supabase JS are external network dependencies; they can delay rendering or fail independently of the static host.
- Live marketplace loading currently uses a bounded range of 60 rows, then a second query for company display data. No explicit user-driven pagination or query debounce exists in the visible homepage.
- No measured LCP, INP, CLS, FCP or mobile network profile is available; performance cannot be rated as passed.
- Responsive breakpoints exist, but no real device/browser matrix has been executed.
- The mobile menu originally changed only a CSS class and did not expose `aria-expanded`/`aria-controls`; this was corrected in the current audit package. Keyboard Escape now closes the menu.
- Modal focus trapping, focus restoration and comprehensive keyboard/screen-reader testing remain unverified.
- `index.html` uses relative social preview image paths. Open Graph/Twitter image URLs should be absolute HTTPS URLs once the production domain is selected.

## 7. Technical debt and maintainability

- Legacy technical identifiers (`window.NEXVORA*`, `__nexvora*`, RPC `nexvora_admin_overview`, Supabase project slug) remain in runtime code intentionally for compatibility. They are not visible brand copy and must not be mass-renamed.
- README contained stale pre-rebrand tagline/palette and inaccurate claims that the auth modal was demo-only; this documentation drift has been corrected in this package.
- Main CSS is compressed into very long lines and includes some duplicated/legacy style declarations; one duplicated `--accent` declaration was removed without changing its value.
- Frontend, auth and data service code is concentrated in a single ES module. Modular service extraction may be considered later, but only with a dependency/behavior map and regression tests.
- No package manifest or lockfile means external dependency resolution is not reproducibly pinned beyond the CDN URL's major version selector.
- Documentation is extensive but contains historical phase reports; preserve them as provenance and distinguish historical records from current status.

## 8. Phase 1 readiness findings

| Requirement | Finding | Status |
|---|---|---|
| ZELQENTRA identity on public pages | Current public HTML/CSS uses ZELQENTRA; legacy strings found only in technical identifiers/config/RPC | PASS (static inspection) |
| Logo and favicon assets | SVG assets exist and local references resolve | PASS (static inspection) |
| SEO title/description | Homepage and legal-page metadata present | PARTIAL |
| Canonical URL / absolute social URL | No confirmed production domain; social image is relative | BLOCKED |
| Mobile navigation | Existing toggle works by class; accessible expanded state added | PASS (static code check only) |
| Official footer contacts | Contact details exist in source but operator confirmation is outstanding | BLOCKED pending owner confirmation |
| Internal links/assets | Local HTML links and referenced assets resolve | PASS (static inspection) |
| JavaScript syntax | `node --check` passes for `app.js` and `backend.js` | PASS (static test only) |
| CSS / JSON / SVG parsing | Both CSS files parse; manifest JSON and eight SVGs parse | PASS (static test only) |
| Supabase deployment config | Browser config present; actual project/migration/Auth state not verified | BLOCKED |
| Browser/mobile visual QA | No deployed browser session or screenshots | BLOCKED |
| Production readiness | Legal, domain, live security and browser tests outstanding | NOT READY |

## 9. Development priorities

### P0 — Complete Phase 1 deployment readiness
1. Confirm final production domain and hosting target.
2. Confirm official business/operator name, public email and phone/WhatsApp details.
3. Configure canonical URL, absolute Open Graph/Twitter image, sitemap and robots policy for the selected domain.
4. Deploy to staging and run desktop/mobile browser QA, navigation, modal, links, asset and console/network checks.
5. Verify Supabase URL/key type, Auth redirect allow-list, migration application state and live read-only connection without exposing secrets.
6. Finalize legal disclosures with actual operator and jurisdiction details before public launch.

### P1 — Core platform foundation
1. Formalize user journeys and permission matrix for buyer, supplier, business partner and admin.
2. Verify Auth, email confirmation, password recovery, session restoration and sign-out in staging.
3. Build role-aware account/company dashboards and profile management.
4. Add explicit input schemas and allow-listed data mapping to browser service methods; enforce all authorization in PostgreSQL/RPC/RLS.
5. Add automated tests for RLS and unauthorized cross-company access before exposing data-management UI.

### P2 — Directory and marketplace
1. Build dynamic company directory with safe public projection, filters and pagination.
2. Build product detail and publishing/moderation workflow.
3. Implement storage upload constraints and server-side content validation.
4. Add indexes only after query-plan evidence and reviewed migration approval.

### P3 — RFQ and commerce workflows
1. Replace non-atomic buyer-request/RFQ creation with a transactional database operation.
2. Build RFQ lifecycle, quotation response/decision, negotiation history and expiry handling.
3. Add messaging, notifications and auditable event history.

### P4 — Trade intelligence and automation
1. Define provenance and licensing for trade datasets.
2. Build ingestion/normalization/quality monitoring before presenting metrics.
3. Add AI only with transparent data sources, evaluation, privacy controls and cost budgets.
4. Add matching and workflow automation with human review and traceable decisions.

## 10. Recommended phase plan

| Phase | Scope | Gate to proceed |
|---|---|---|
| Phase 1 | Brand integration and deployment readiness | Domain/contact confirmation, deployed browser QA, Supabase preflight, legal review |
| Phase 2 | Core platform foundation | Auth + role matrix + RLS tests + account/company dashboard |
| Phase 3 | Global business directory | Dynamic DB data, public-field privacy, filters/pagination, access tests |
| Phase 4 | Product marketplace | Listing lifecycle, moderation, detail pages, upload security |
| Phase 5 | RFQ & quotation engine | Atomic RFQ creation, supplier/buyer permission tests, lifecycle UI |
| Phase 6 | Trade intelligence | Licensed/provenanced datasets, reproducible metrics, AI transparency |
| Phase 7 | Automation ecosystem | Auditable workflows, rate limits, monitoring, cost controls, rollback |

## 11. Changes made in this audit package

Only low-risk Phase 1 accessibility/documentation corrections were made:
- Mobile menu button now declares `aria-controls` and `aria-expanded` and has an explicit button type.
- Mobile menu JavaScript synchronizes expanded/label state, closes after navigation and closes on Escape.
- Removed one duplicate CSS design-token declaration without changing the token value.
- Corrected README brand slogan/positioning, palette reference and outdated description of Auth behavior.

**Not changed:** database schema, SQL migrations, RLS, grants, triggers, functions, Supabase URL/key values, business workflows, APIs, framework, architecture, brand assets or existing product features.

## 12. Test evidence and limitations

- ZIP integrity: PASS (`testzip()` returned no corrupt entry).
- `node --check app.js`: PASS.
- `node --check backend.js`: PASS.
- CSS parse (`styles.css`, `legal.css`): PASS, zero parser errors.
- `manifest.webmanifest`: PASS JSON parse.
- SVG assets: PASS XML parse (8 files).
- Local links in `index.html`, `privacy.html`, `terms.html`: PASS; no missing local targets found.
- Duplicate HTML IDs in inspected pages: none found.
- SQL migration files were not modified.
- No browser test, Supabase integration test, RLS test, Auth email test, production test, legal review or Core Web Vitals measurement was executed.

**Conclusion:** this package is a Phase 1 readiness/audit build, not a production-ready launch certification. Complete the external blockers and browser/integration tests before declaring Phase 1 done.
