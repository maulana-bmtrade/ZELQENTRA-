# ZELQENTRA — Complete B2B Platform Rebranding Report

**Version:** 1.0  
**Date:** 3 November 2026  
**Source of truth:** user-provided `NEXVORA_B2B_Phase2.3_B3_Business_Identity_Readiness.zip`  
**Deliverable:** `NEW_BRAND_B2B_COMPLETE_REBRANDING_V1.zip`

## Executive summary

The supplied project has been rebranded from its former public working identity **NEXVORA B2B** to **ZELQENTRA**. The new positioning is **Global Trade Intelligence Network**, with the slogan **“Connect with clarity. Trade with confidence.”**

This is a controlled identity-only change. The existing static HTML/CSS/vanilla JavaScript architecture, page structure, DOM IDs, app workflows, Supabase client setup, SQL migrations, RLS definitions, API/service function names and business demo records were preserved.

The new brand is a strategic working recommendation, not a legally cleared trademark. The initial web screening did not surface an exact indexed ZELQENTRA result; WIPO, PDKI, national registers, registrar/RDAP, social handles and app-store availability have not been comprehensively cleared.

## Brand decision

- **Brand:** ZELQENTRA
- **Descriptor:** Global Trade Intelligence Network
- **Slogan:** Connect with clarity. Trade with confidence.
- **Supporting line:** The intelligence layer for global trade.
- **Positioning:** a B2B discovery and trade-intelligence ecosystem, not a generic online catalogue.
- **Logo concept:** a custom geometric Z route linking four network nodes.
- **Primary palette:** Midnight Navy `#101B2D`, Signal Teal `#38D6C4`, Intelligent Blue `#6B8CFF`, Ice Background `#F3F7FB`.
- **Typography:** Manrope for headings; DM Sans for body and interface text.

Full research and guidelines:
- `BRAND_NAME_RESEARCH.md`
- `BRAND_IDENTITY_GUIDELINES.md`
- `BRAND_FILE_INVENTORY.md`

## Controlled change log

| File | Before | After | Reason | Verification |
|---|---|---|---|---|
| `index.html` | NEXVORA public text, old SEO metadata, old favicon, no manifest/Organization metadata | ZELQENTRA copy, revised title/description/OG/Twitter, new favicon, Apple icon, manifest and minimal Organization JSON-LD | Consistent public identity and digital metadata | PASS — HTML refs, IDs and script order checked |
| `styles.css` | Navy/lime/blue identity tokens | Midnight Navy / Teal / Intelligent Blue tokens and matching accent shades | New visual identity without layout redesign | PASS — stylesheet parser |
| `legal.css` | Former green accent | Zelqentra teal accent | Legal pages match the new identity | PASS — stylesheet parser |
| `assets/nexvora-mark.svg` | Former mark | Removed after all live references were migrated | Retire obsolete public logo asset | PASS — no live reference remains |
| `assets/zelqentra-symbol.svg` | Not present | New node-route symbol | Header, favicon and brand symbol | PASS — XML parse |
| `assets/zelqentra-logo.svg` | Not present | New horizontal primary logo | Primary logo system | PASS — XML parse |
| `assets/zelqentra-monochrome.svg` | Not present | New monochrome logo | One-colour use | PASS — XML parse |
| `assets/zelqentra-app-icon.svg` | Not present | New app icon | App/PWA identity | PASS — XML parse |
| `assets/favicon.svg` | Not present | New favicon | Browser identity | PASS — XML parse |
| `assets/zelqentra-social.svg` | Not present | 1200×630 social artwork | Open Graph/Twitter preview | PASS — XML parse |
| `manifest.webmanifest` | Not present | Zelqentra PWA name, theme and icon | App identity metadata | PASS — JSON parse |
| `app.js` | Marketplace art label says NEXVORA MARKETPLACE | ZELQENTRA MARKETPLACE | Public-facing brand text only | PASS — syntax; one string changed |
| `backend.js` | Auth copy and console tags say NEXVORA | Zelqentra auth copy and logs | User-facing identity consistency | PASS — syntax; only string literals changed |
| `privacy.html` | NEXVORA brand in title, content and footer | Zelqentra identity and favicon | Legal-page brand consistency | PASS — local references |
| `terms.html` | NEXVORA brand and IP wording | Zelqentra identity and favicon | Legal-page brand consistency | PASS — local references |
| `README.md` | Former platform identity | Zelqentra brand and new asset references | Current project documentation | PASS — static review |
| `PROJECT_BRIEF.md` | Former platform identity | Zelqentra positioning and brand section | Current product brief | PASS — static review |
| `BACKEND_SETUP.md` | Former brand in setup instructions | Zelqentra public brand; legacy Supabase slug and JS global preserved | Current setup documentation | PASS — static review |
| `TEST_PLAN.md` | Former brand/package reference | Current package name and Zelqentra context | Current testing documentation | PASS — static review |
| `supabase-config.js` | Former brand in a comment | Zelqentra comment; URL and anonKey unchanged | Configuration documentation only | PASS — values preserved |
| Historical Phase 2.x / Phase 2.3 reports | Former brand as historical context | Historical identity notice added; original technical record retained | Preserve audit provenance | PASS — retained as historical records |

## Files deliberately not changed

### Database and backend contract
- All three migration SQL files.
- `supabase/VALIDATION_QUERIES.sql`.
- `supabase-config.example.js`.
- `.gitignore`.
- Supabase Project URL and Publishable Key values in `supabase-config.js` (values unchanged; key not reproduced here).
- Database tables, columns, constraints, functions, triggers, RLS and Storage policies.
- `window.NEXVORA`, `window.NEXVORA_SUPABASE`, `window.NEXVORA_API`, `__nexvora*` and `nexvora_admin_overview`.

### Application behavior
- Authentication and session flows.
- Buyer/Supplier role handling.
- Company workspace logic.
- Product data/service methods.
- RFQ and quotation service methods.
- Connection-status logic.
- Form submission and consent behavior.
- DOM IDs, navigation targets and JavaScript event wiring.
- Product demo records and contact details.

The public strings in `app.js` and `backend.js` were changed only where they displayed the old platform brand. No business logic was intentionally edited.

## Technical invariants checked

- Baseline archive contained 28 files.
- Rebranded source contains 41 files.
- New files: 14.
- Removed/renamed file: `assets/nexvora-mark.svg` (replaced by the new Zelqentra logo family).
- Existing files modified: 21.
- All three SQL migration files and `VALIDATION_QUERIES.sql` are byte-for-byte unchanged.
- Supabase Project URL and Publishable Key values in `supabase-config.js` are unchanged.
- Existing DOM IDs: 22 before and 22 after; no additions or removals.
- Existing script order remains: `supabase-config.js` → `app.js` → `backend.js`.
- Existing local HTML/CSS/JS page structure remains in place.
- No new JavaScript dependency or framework was introduced.

## Known limitations and risks

1. **Trademark:** no legal clearance is claimed. The initial general-web screen is not a substitute for WIPO/PDKI/USPTO/EUIPO/TMview and national-register searches.
2. **Domain:** no official domain was supplied. Canonical URL is intentionally absent. Social preview image uses a relative path and should be updated to an absolute HTTPS URL after the domain is selected.
3. **Social and app stores:** usernames and app-store names have not been confirmed.
4. **Legal operator:** the operator's legal name, registered address, governing law and data-controller details remain owner/legal-counsel tasks. The rebrand does not invent a new legal entity.
5. **Visual QA:** source-level checks passed, but a live browser screenshot/interaction pass on Android and desktop was not available in this execution.
6. **Supabase:** no database connection, migration or authentication test was run as part of this rebranding task.

## Release decision

**Identity implementation:** COMPLETE at source level.  
**Application behavior regression:** static checks PASS; live visual checks BLOCKED.  
**Trademark/domain clearance:** BLOCKED pending official searches and owner decisions.  
**Supabase/database:** unchanged and not tested in this rebranding phase.

The ZIP is a rebranded source package, not a statement that the platform is production-ready or that the new name is legally available.
