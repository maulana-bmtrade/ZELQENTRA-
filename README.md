# ZELQENTRA B2B — Website Foundation

**Positioning:** Global Trade Intelligence Network.

**Slogan:** Connect with clarity. Trade with confidence.

**Supporting tagline:** The intelligence layer for global trade.

This ZIP contains the first visual and interaction foundation for the ZELQENTRA B2B website. It translates the supplied product vision into a responsive, mobile-first landing experience.

## Run locally
1. Extract the ZIP.
2. Open `index.html` in a modern browser.
3. For a local development server, run `python -m http.server 8000` from this folder and open `http://localhost:8000`.

No build step or paid dependency is required for this static foundation.

## Included
- International-facing homepage and brand identity.
- Responsive desktop and mobile layouts.
- Marketplace sample listing cards.
- Product keyword search and category filtering.
- Business Network and Trust pillar presentation.
- AI Business Intelligence concept section.
- Supabase-backed signup, login, password-reset and session handling when configured; demo mode is explicitly labelled when not configured.
- Basic accessibility labels and reduced-motion support.
- SEO title, description, theme color and SVG favicon.

## Important implementation status
This is a **frontend foundation / interactive concept prototype**, not a production marketplace backend.

The following are deliberately not represented as live services yet:
- Real user registration, login, password reset or role-based authorization.
- Persistent company profiles or product publishing.
- Live supplier directory or verified-company checks.
- RFQ submission, quotation workflows or messaging.
- Real notifications, admin moderation or payment/subscription processing.
- AI matching, demand analytics or external market data.

When Supabase is not configured, the registration modal is not connected and sample marketplace listings are shown. When configured, authentication is handled through Supabase Auth and the homepage attempts a read-only marketplace query. The company directory, RFQ and quotation API surface is not yet exposed as complete user workflows.

## Recommended next engineering phase
1. Confirm product requirements and user journeys for Buyer, Supplier, Business Partner and Admin.
2. Establish a Git repository and environment configuration.
3. Implement authentication and authorization with a managed identity provider.
4. Design PostgreSQL schema for companies, users, memberships, products, categories, RFQs, quotations, messages, notifications and verification records.
5. Add server-side validation, audit logging, rate limiting and secure file handling.
6. Connect marketplace search, company directory and RFQ workflows to the database.
7. Build role-specific dashboards and admin moderation.
8. Add automated tests, backups, monitoring and deployment pipeline.
9. Conduct security, privacy, performance and accessibility reviews before production launch.

## Suggested initial data entities
- `users`
- `companies`
- `company_members`
- `business_verification`
- `products`
- `product_categories`
- `rfqs`
- `quotations`
- `business_connections`
- `conversations`
- `messages`
- `notifications`
- `subscriptions`
- `audit_events`

## Project structure
```
ZELQENTRA_B2B/
├── index.html
├── styles.css
├── app.js
├── README.md
└── assets/
    └── zelqentra-symbol.svg
```

## Brand direction
- Deep navy: trust, depth and enterprise capability.
- Signal Teal (#38D6C4) and Intelligent Blue (#6B8CFF) accents.
- Typography: Manrope + DM Sans.
- Visual language: minimal, premium, clear, global and mobile-first.

Before production use, configure the final HTTPS domain and absolute social-sharing image URL, confirm official operator/contact details, finalize legal disclosures, verify Supabase Auth redirect URLs and migration state, and complete browser-level security and regression tests.


## Phase 2.2 — Supabase activation readiness
See `PHASE21_AUDIT.md`, `PHASE22_AUDIT.md`, `BACKEND_SETUP.md`, and `TEST_PLAN.md`. Three ordered Supabase migrations are included. The project remains inactive until the user configures the browser-safe Project URL/publishable-or-anon key and applies the migrations in a real Supabase project. Live database, Auth, Storage and RLS tests are not claimed as passed. Never place a Supabase service-role or secret key in browser code.

## Phase 2.3 — Repository audit package
The latest Phase 2.3 work completed Phase A (static repository audit) only. See `PHASE23_PHASE_A_REPOSITORY_AUDIT.md` and `PHASE23_SOURCE_PACKAGE_NOTES.md`. The complete Phase 2.2 source tree and its three migrations are preserved in this package. Supabase activation and real database tests remain blocked until the owner configures the Project URL and browser-safe publishable/anon key locally and confirms the migration state of the target project. No real database test is claimed as passed.


## Phase 2.3 B.1 — Deployment configuration
`supabase-config.js` is intentionally included in Git-based deployments and is no longer excluded by `.gitignore`. It must contain only the Project URL and browser-safe Supabase Publishable/legacy anon key. Never place a Secret Key, `service_role`, database password, or other server secret in browser files. See `PHASE23_PHASE_B1_DEPLOYMENT_REPORT.md`.

## Phase 2.3 — B.3 Business Identity & Platform Readiness

This release adds preliminary `privacy.html` and `terms.html` pages, links them from the site footer, and requires new registrations to acknowledge the Terms of Service and Privacy Policy. The consent checkbox is hidden for login and password-reset flows. The existing Supabase project configuration, database migrations and backend data model are unchanged.

**Legal readiness limitation:** the legal pages are preliminary website disclosures, not legal advice or a final jurisdiction-specific contract. The platform operator's full legal name, business address, applicable governing law and final processing/retention details must be confirmed and reviewed before public commercial launch. Do not represent these draft pages as final legal approval.

**Feature truthfulness:** the homepage still contains curated/sample visual listings when Supabase is not configured. The live marketplace state is only shown after the read-only Supabase check succeeds. AI intelligence visuals are currently explanatory UI and are not a live AI service. Do not treat sample cards, verification-style visuals or illustrative market indicators as actual verified offers or analytics.


## Current brand identity — ZELQENTRA

The public-facing platform brand is now **ZELQENTRA**. The positioning is **Global Trade Intelligence Network** and the slogan is **“Connect with clarity. Trade with confidence.”**

See `BRAND_IDENTITY_GUIDELINES.md` for the complete visual and verbal system, and `BRAND_NAME_RESEARCH.md` for the preliminary name-screening caveats. Historical engineering reports retain the former working name where needed to preserve technical provenance. Legacy Supabase/JavaScript identifiers and the Supabase project slug remain unchanged intentionally.
