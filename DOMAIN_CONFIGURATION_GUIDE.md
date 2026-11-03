# ZELQENTRA Domain & Deployment Configuration Guide

**Public brand:** ZELQENTRA  
**Canonical domain:** `https://zalqentra.biz.id`  
**Important spelling:** brand uses **E**; domain uses **A** (`zalqentra.biz.id`).

## 1. Canonical and SEO implementation

The homepage and public legal pages now declare absolute canonical URLs on `https://zalqentra.biz.id`. Open Graph and Twitter images point to `https://zalqentra.biz.id/assets/zelqentra-social.svg`. `robots.txt` advertises `https://zalqentra.biz.id/sitemap.xml`.

The sitemap currently includes only the three public HTML pages present in this source: `/`, `/privacy.html`, and `/terms.html`. Do not add private application URLs until those routes exist and are intentionally public. The current authentication experience is a modal on the homepage, not a separate route.

## 2. DNS and custom-domain setup

DNS records depend on the selected hosting provider. Do not copy arbitrary A/AAAA/CNAME values from another host.

1. In the hosting provider dashboard, add `zalqentra.biz.id` as a custom domain.
2. Copy the exact DNS record type, name/host and target/value supplied by that provider.
3. At the domain registrar/DNS manager, create those records exactly. Remove conflicting records only after confirming they are obsolete.
4. Wait for DNS propagation and confirm the provider reports the domain as verified.
5. Enable the provider-managed TLS/SSL certificate and wait until issuance is complete.
6. Test `https://zalqentra.biz.id/`, the legal pages, `robots.txt`, `sitemap.xml`, and all referenced assets.

Do not assume the hosting provider or DNS records from this source. No DNS changes or deployment were performed as part of this release.

### Optional `www` hostname

This release does **not** assume `www.zalqentra.biz.id` will be used. If you decide to support it:

- Add `www.zalqentra.biz.id` as an additional custom domain at the host.
- Create only the DNS record instructed by the host.
- Configure a permanent HTTPS redirect from `https://www.zalqentra.biz.id/*` to `https://zalqentra.biz.id/:splat` (redirect syntax varies by host).
- Add `https://www.zalqentra.biz.id/**` to Supabase Allowed Redirect URLs only if the `www` hostname can actually serve the application or is a deliberate callback origin.
- Keep canonical URLs on the non-www hostname.

## 3. HTTPS, SSL and mixed content

- Require HTTPS at the host and enable its HTTP-to-HTTPS redirect.
- If `www` is enabled, redirect it to the canonical non-www host after TLS is valid for both hostnames.
- Verify certificate hostname coverage, issuer and expiry in a browser or TLS inspection tool.
- Check browser DevTools Console and Network for mixed-content warnings. All first-party canonical and social metadata URLs in this release use HTTPS.
- Third-party dependencies (Google Fonts and the Supabase JS CDN) are already requested over HTTPS.

## 4. Supabase Authentication Dashboard

The source now sends sign-up confirmation and password-reset links back to the root of the current serving origin. When the application is served from the canonical domain, the resulting target is `https://zalqentra.biz.id/`. Local development retains its local origin.

In Supabase Dashboard → Authentication → URL Configuration, set:

**Site URL**

`https://zalqentra.biz.id`

**Allowed Redirect URLs**

`https://zalqentra.biz.id/**`

For local development only, add the exact local origin you use, for example:

`http://localhost:8000/**`

Add `https://www.zalqentra.biz.id/**` only if `www` is configured and intentionally supported. Avoid broad wildcard domains.

### Auth flow notes

- **Login:** password sign-in; no email redirect is needed for the immediate login response.
- **Registration/email confirmation:** `emailRedirectTo` is the root of the current origin.
- **Password recovery:** `redirectTo` is the root of the current origin.
- **Callback/session processing:** the Supabase client has `detectSessionInUrl: true`; the homepage processes the returned auth URL. There is no dedicated `/auth/callback` route in this source.
- **Logout:** calls Supabase `signOut()` and refreshes the local session UI; it does not require a redirect URL.

After saving Dashboard settings, test a real confirmation email and password reset with a controlled test account. Confirm the email template's confirmation/reset links use Supabase's supported confirmation URL variables and do not hardcode the previous host. Do not send or expose any Secret Key or `service_role` key.

**Important:** Editing this repository does not update Supabase Dashboard settings. Those settings remain a manual external action and were not changed or verified here.

## 5. Deployment checklist

1. Upload the contents of the release ZIP to the configured static host (not the ZIP file itself unless the host expects an archive).
2. Attach `zalqentra.biz.id` as the custom domain.
3. Configure provider-prescribed DNS records.
4. Wait for domain verification and HTTPS certificate issuance.
5. Configure canonical-host redirect behavior at the host.
6. Set Supabase Site URL and Allowed Redirect URLs as above.
7. Verify homepage, legal pages, manifest, favicon, social image, robots and sitemap over HTTPS.
8. Test registration confirmation, login, password recovery and logout.
9. Inspect browser console/network for JavaScript errors, failed assets and mixed content.
10. Submit the sitemap in the relevant search-engine webmaster tools after the site is publicly reachable.

## 6. DNS and propagation checks

From a terminal, use commands such as:

```sh
nslookup zalqentra.biz.id
nslookup www.zalqentra.biz.id
```

The `www` lookup is relevant only if that hostname is configured. Compare returned records with the exact targets shown by the hosting provider. DNS propagation is not instantaneous and can vary with resolver caching/TTL.

After DNS resolves, check HTTPS in a browser and optionally:

```sh
curl -I https://zalqentra.biz.id/
curl -I https://zalqentra.biz.id/robots.txt
curl -I https://zalqentra.biz.id/sitemap.xml
```

Expected outcomes: successful HTTPS response, valid certificate, and no redirect loop. A redirect to another host should end at `https://zalqentra.biz.id/`.

## 7. Outstanding owner decisions/actions

- Confirm which hosting provider will serve the site and configure its custom domain.
- Add the provider-prescribed DNS records.
- Decide whether the `www` hostname is needed.
- Configure Supabase Site URL and Allowed Redirect URLs in the dashboard.
- Review Supabase email templates and run live auth tests.
- Confirm the public operator's legal identity and contact details before commercial launch; this release does not invent or replace them.
- After deployment, replace no canonical URLs unless the domain changes through an explicit owner decision.
