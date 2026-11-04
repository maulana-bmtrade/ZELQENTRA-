# Security report

## Implemented safeguards in this change
- Public company reads use only `public_company_directory` with its existing restricted field projection.
- Public product reads remain constrained to `status = 'published'`.
- User-visible database values are escaped before insertion into HTML templates.
- Company profile route accepts a UUID-shaped identifier and still resolves through the public directory view.
- Product detail remains constrained to published products.
- No Secret/service_role key was added. The existing browser configuration uses a Publishable key.
- `.env.example` contains placeholders only.

## Known limitations / verification required
- This is a static frontend. Supabase RLS remains the authorization boundary for writes and authenticated data.
- Live RLS, cross-company isolation, Auth session lifecycle, Storage bucket policy, and upload validation have not been tested against the live project.
- The company directory view intentionally omits private company fields; do not query `companies` anonymously.
- The existing product image helper renders only complete HTTPS URLs; it does not infer public Storage URLs for private buckets.
- Run dependency and browser security scans before production. External CDN dependency availability and CSP headers are hosting concerns.

## Status
Static source review: performed. Live penetration test: NOT TESTED. Supabase policy verification: BLOCKED without project access.

## Phase 2 security implementation

See `SECURITY_PHASE2.md` and `SUPABASE_PHASE2_SETUP.md`. The additive migration introduces private conversation attachment policies, manager-scoped invitation/member RPCs, protected buyer request and quotation transitions, trusted product/company moderation RPCs, and database-generated notifications. The migration has not been applied to the live project in this release. Existing live Storage policies must be inspected because permissive policies are OR-combined. Cross-company RLS and two-account security tests remain NOT TESTED/BLOCKED.
