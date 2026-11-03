# ZELQENTRA — DNS Configuration Guide (GitHub Pages)

**Canonical domain:** `zalqentra.biz.id`  
**Hosting target:** GitHub Pages  
**Canonical URL:** `https://zalqentra.biz.id/`

## 1. Verify ownership and configure GitHub first

For protection against domain takeover, verify the domain in GitHub account settings using the TXT record GitHub generates. Do not invent the TXT value; copy the exact value shown by GitHub. Then add `zalqentra.biz.id` under the repository's **Settings → Pages → Custom domain**. GitHub recommends verifying the domain before adding it to a Pages site.

## 2. Apex DNS records

At the DNS provider that is authoritative for `zalqentra.biz.id`, configure these four records:

| Type | Host/Name | Value | TTL |
|---|---|---|---|
| A | `@` | `185.199.108.153` | Provider default / 3600 |
| A | `@` | `185.199.109.153` | Provider default / 3600 |
| A | `@` | `185.199.110.153` | Provider default / 3600 |
| A | `@` | `185.199.111.153` | Provider default / 3600 |

IPv6 is optional. If enabled, add all four official GitHub Pages AAAA records:

| Type | Host/Name | Value |
|---|---|---|
| AAAA | `@` | `2606:50c0:8000::153` |
| AAAA | `@` | `2606:50c0:8001::153` |
| AAAA | `@` | `2606:50c0:8002::153` |
| AAAA | `@` | `2606:50c0:8003::153` |

Do not create a `www` record yet. The requested canonical host is the apex domain and the repository CNAME is `zalqentra.biz.id`. A `www` alias can be added later only after deciding to support it and knowing the actual GitHub Pages hostname (`USERNAME.github.io` or `ORGANIZATION.github.io`). No username or organization is assumed here.

## 3. Conflicts and DNS hygiene

- Remove stale/conflicting apex `A`, `AAAA`, or `ALIAS/ANAME` records that point somewhere other than the selected GitHub Pages configuration.
- Do not create wildcard DNS records (`*`).
- Do not point a `www` CNAME to the apex as a substitute for the GitHub Pages hostname; GitHub's documented CNAME target is the account's `*.github.io` hostname.
- Check existing `CAA` records. If the zone restricts certificate authorities, ensure GitHub Pages' certificate issuance is not blocked. Do not delete unrelated mail records (MX, SPF, DKIM, DMARC) while changing website records.
- If a DNS provider offers proxying, use DNS-only mode during initial GitHub Pages domain verification and certificate issuance unless the provider's documented setup explicitly supports proxying GitHub Pages.

## 4. Propagation and verification

DNS changes may take up to 24 hours to propagate. From a terminal, check:

```sh
dig zalqentra.biz.id A +short
dig zalqentra.biz.id AAAA +short
dig zalqentra.biz.id CAA +short
```

The A answers should include all four GitHub Pages IPv4 addresses. If AAAA records are configured, the AAAA answers should include the four IPv6 addresses above.

Then check HTTPS:

```sh
curl -I https://zalqentra.biz.id/
curl -I https://zalqentra.biz.id/robots.txt
curl -I https://zalqentra.biz.id/sitemap.xml
```

A browser lock icon alone is not sufficient; also inspect the certificate hostname, validity dates, and browser console for mixed content. Enable **Enforce HTTPS** in GitHub Pages only after the certificate is available.

## 5. Supabase Auth dashboard (manual)

In Supabase Dashboard → Authentication → URL Configuration:

- **Site URL:** `https://zalqentra.biz.id`
- **Allowed Redirect URLs:** `https://zalqentra.biz.id/**`
- Add localhost redirect patterns only if local development is actively used.

This package does not change Supabase dashboard settings. The app currently builds signup and password-recovery redirect URLs from `window.location.origin`, so the production origin becomes the apex domain once served there. Keep the Supabase Project URL and Publishable Key unchanged. Never enter or expose a Secret Key or `service_role` key in frontend code.

## Official references

- [GitHub DNS records and custom domains](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site)
- [GitHub HTTPS guidance](https://docs.github.com/en/pages/getting-started-with-github-pages/securing-your-github-pages-site-with-https)
- [GitHub custom-domain verification](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/verifying-your-custom-domain-for-github-pages)
