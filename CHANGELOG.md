# Changelog

## 1.0.0 (2026-11-04)
- Based on the uploaded `ZELQENTRA--main.zip` source archive.
- Added public Company Directory page backed only by `public_company_directory`.
- Added public Company Profile route showing directory-safe fields and published company products.
- Added supplier profile navigation from marketplace product cards and product detail pages.
- Added minimum/maximum listed price and MOQ filters to product discovery.
- Added responsive company directory styling, loading/empty/error states, and sitemap entries.
- Removed synthetic product fallback from the landing page; live catalog records are not fabricated.
- Added installation, deployment, database migration, security, and test documentation.
- No Supabase schema migration was introduced.


## Independent audit V1.0.1 (2026-11-04)
- Independently inspected the V1.0.0 ZIP contents and reran static checks.
- Corrected backend status badge tooltip so setup mode does not claim demo listings are shown.
- Added `INDEPENDENT_AUDIT_REPORT_V1.0.1.md` with feature-by-feature evidence and honest test statuses.
- Product management UI, full workspace, RFQ/quotation UI, messaging/attachments, notifications and admin dashboard remain unimplemented.
