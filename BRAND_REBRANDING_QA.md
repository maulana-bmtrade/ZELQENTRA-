# ZELQENTRA — Rebranding Quality Assurance Report

**Date:** 3 November 2026  
**Test scope:** controlled identity transformation of the supplied Phase 2.3 B.3 source ZIP.

## Results

| Test | Result | Evidence / limitation |
|---|---|---|
| JavaScript syntax — `app.js` | PASS | `node --check app.js` |
| JavaScript syntax — `backend.js` | PASS | `node --check backend.js` |
| CSS parse — `styles.css` | PASS | `tinycss2` stylesheet parse; no parse errors |
| CSS parse — `legal.css` | PASS | `tinycss2` stylesheet parse; no parse errors |
| SVG XML parse | PASS | All SVG assets parse as XML |
| PWA manifest JSON | PASS | `manifest.webmanifest` parses; name and icon references exist |
| HTML local asset references | PASS | No missing local `src` / `href` references in `index.html`, `privacy.html` or `terms.html` |
| DOM ID regression | PASS | Same 22 IDs before and after; no IDs removed or added |
| JavaScript script order | PASS | `supabase-config.js`, then `app.js`, then module `backend.js` |
| CSS responsive breakpoints | PASS — static | Existing breakpoints retained; no layout rule rewrite intended |
| Supabase configuration values | PASS — unchanged | Project URL and anonKey values match baseline; key value is not reproduced |
| Migration SQL integrity | PASS | Three migration files byte-for-byte identical to baseline |
| Validation query integrity | PASS | `VALIDATION_QUERIES.sql` byte-for-byte identical to baseline |
| Auth/business logic diff | PASS — static | Only public-facing brand strings/log labels changed in `backend.js`; only marketplace label changed in `app.js` |
| Secret scan | PASS — pattern scan | No `sb_secret_` credential, assigned service-role secret, PEM private key or hardcoded database password pattern found |
| Live browser visual check | BLOCKED | No deployed browser screenshot/interaction session in this execution |
| Android/desktop manual responsive check | BLOCKED | Must be performed on the target deployment |
| Trademark and domain clearance | BLOCKED | Official register and registrar checks remain outstanding |
| Supabase connection/auth regression | NOT RUN | Database and Auth were intentionally not touched in this rebranding task |

## Important security distinction

The configured Supabase browser key remains the existing **Publishable Key**. Publishable keys are intended for client-side use and are not Secret Keys. The scan did not reproduce the key in this report. No `sb_secret_` or `service_role` credential was added. RLS remains the actual database authorization boundary.

## Manual release checklist

Before publishing:
1. Complete official trademark similarity searches for ZELQENTRA in Indonesia and the intended target markets.
2. Verify the chosen domain via registrar/RDAP and register it if appropriate.
3. Reserve social usernames and check app-store name conflicts.
4. Set the final absolute HTTPS Open Graph image URL and canonical URL after the domain is selected.
5. Open the deployed site on Android Chrome and desktop Chrome/Firefox/Safari.
6. Check header/footer logo, favicon, social preview, mobile navigation, marketplace filters, auth modal, legal pages and browser console.
7. Confirm no historical name is visible in customer-facing pages; historical engineering reports may retain it with the historical identity notice.
8. Run the existing Supabase/Auth/RLS regression plan separately. No database operation was performed here.

## Conclusion

The source-level rebrand passes the static integrity checks above. This does not constitute live browser certification, legal trademark clearance, or Supabase production validation.
