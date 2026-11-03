# ZELQENTRA — GitHub Pages Deployment Guide (Phase 1.2)

## Publishing model

This project is a static site: `index.html`, `privacy.html`, `terms.html`, CSS, JavaScript, SVG assets, and Supabase browser configuration are already in the repository root. It has no required build step or package installation. **Use GitHub Pages publishing from a branch, deploying the repository root**. This avoids introducing an unnecessary build system or GitHub Actions workflow.

The root `CNAME` file contains only `zalqentra.biz.id`. `.nojekyll` disables Jekyll processing so GitHub Pages serves the static tree as-is. No SPA fallback is added; the site uses real files and fragment navigation, not client-side URL routing.

## Before publishing

1. Create or choose the GitHub repository that will own the website. The repository name and GitHub username are intentionally not assumed in this guide.
2. Review the repository visibility decision. GitHub Pages on GitHub Free requires a public repository. A public repository exposes all committed source files, including the Supabase Project URL and browser-safe Publishable Key in `supabase-config.js`. That key is designed for browser use; database security must come from RLS and least-privilege grants. Never commit `sb_secret_*`, `service_role`, passwords, private keys, or other server credentials.
3. Keep the website files at the repository root. `index.html`, `CNAME`, `.nojekyll`, `robots.txt`, and `sitemap.xml` must be at that root. Preserve `assets/` and `supabase/` directories.
4. Do not upload the ZIP as the only repository file. Extract it first, then upload its contents while preserving directory structure.

## Enable GitHub Pages (branch publishing)

1. Open the repository on GitHub.
2. Go to **Settings → Pages**.
3. Under **Build and deployment**, select **Deploy from a branch**.
4. Select the branch containing the source (commonly `main`, but use the branch that actually exists).
5. Select **/(root)** as the folder, then Save.
6. Under **Custom domain**, enter `zalqentra.biz.id` and save. The root `CNAME` file in this package also records the same domain for branch publishing.
7. Wait for the Pages deployment to complete. Check the Actions/Pages deployment status shown by GitHub.
8. Once DNS resolves and GitHub has issued the certificate, enable **Enforce HTTPS** in Settings → Pages.

No GitHub Actions workflow is included because branch publishing is the simplest fit for this no-build static site. If the project later needs a build or automated tests, add a workflow in a separately reviewed phase. If publishing through a custom Actions workflow in the future, GitHub ignores the `CNAME` file; set the custom domain in Pages settings and ensure the deployed artifact contains the correct site root.

## Android upload path (without a local Git tool)

1. Download `ZELQENTRA_PHASE1_2_GITHUB_PAGES_V1.2.zip` to the Android device.
2. Extract it with the phone's file manager into a folder, for example `ZELQENTRA-PHASE1.2`.
3. In Chrome, open GitHub and sign in. Create the repository if it does not already exist.
4. Open the repository and use **Add file → Upload files**. Select the extracted project contents, not the ZIP itself. Preserve the `assets` and `supabase/migrations` directory hierarchy. If the Android file picker cannot select folders or too many files at once, upload the root files first, then upload the contents of `assets/`, `supabase/`, and `supabase/migrations/` in separate batches while preserving their paths. Do not flatten folders.
5. Commit the upload to the chosen publishing branch.
6. Follow **Enable GitHub Pages** above.

Alternative for users comfortable with a terminal: clone the empty repository, copy the extracted project contents into the clone, then `git add`, `git commit`, and `git push`. Do not use a force push to overwrite an existing repository history.

## After deployment checks

- Confirm `https://zalqentra.biz.id/` opens.
- Confirm `https://zalqentra.biz.id/privacy.html` and `/terms.html` open.
- Confirm `/robots.txt`, `/sitemap.xml`, `/manifest.webmanifest`, `/assets/favicon.svg`, and `/assets/zelqentra-social.svg` return successfully.
- Inspect browser DevTools/console and Network panel for failed assets, JavaScript exceptions, mixed content, and blocked Supabase requests.
- Test signup, email confirmation, login, password reset, session restore, and logout only after the Supabase dashboard URLs and email templates are configured.

## Rollback

Before replacing a live branch, keep the previous deployment commit. If the new deployment fails, use GitHub's commit history to revert the deployment commit or restore the previous known-good tree. Do not delete the CNAME or migration history during rollback.

## Official references

- [GitHub Pages publishing sources](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site)
- [Managing a custom domain](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site)
- [Securing GitHub Pages with HTTPS](https://docs.github.com/en/pages/getting-started-with-github-pages/securing-your-github-pages-site-with-https)
