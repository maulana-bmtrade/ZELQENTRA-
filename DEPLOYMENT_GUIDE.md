# Deployment guide

The supplied project is a static site (HTML, CSS, browser JavaScript modules). No Node build pipeline or server-side runtime is present.

1. Extract the ZIP.
2. Upload the contents of the project root to the hosting document root / GitHub Pages root.
3. Preserve `CNAME`, `.nojekyll` (if present in your source/deployment setup), `robots.txt`, `sitemap.xml`, and the `assets`, `marketplace`, `companies`, and `supabase` directories.
4. Preserve the existing custom domain and HTTPS configuration. Do not replace DNS or CNAME unless your hosting provider explicitly requires it.
5. Configure `supabase-config.js` with the Supabase Project URL and Publishable key.
6. Verify the root, marketplace, product detail, company directory, and company profile routes.
7. Confirm browser network requests use only the expected public directory view and published product rows.

## Hosting notes
- Static hosting is appropriate for the current frontend architecture.
- There is no SPA router; the pages are ordinary HTML routes and do not require SPA fallback rewrites.
- `supabase-config.js` is the runtime configuration file. `.env.example` is explanatory only and is not read by the browser.
- Supabase schema, Auth, RLS, and Storage must be configured separately in the existing Supabase project.

## Phase 2 routes and access

- `/workspace/` — requires an authenticated Supabase user and company membership.
- `/workspace/admin.html` — requires `public.users.role = 'platform_admin'`.
- Workspace routes are marked `noindex,nofollow` and disallowed in `robots.txt`.

Deploy the complete directory tree without changing the existing custom domain. The workspace pages load the same `supabase-config.js` Publishable key and the same Supabase JS client as Marketplace.
