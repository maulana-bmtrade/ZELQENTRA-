# ZELQENTRA Phase 2 Security Notes

## Controls retained

- Existing RLS remains enabled; no policy is disabled and no table is dropped.
- Public company discovery continues to use `public_company_directory`, not anonymous SELECT on `companies`.
- Public Marketplace continues to filter `products.status = 'published'`.
- Browser code uses only the configured Supabase Publishable key. No service-role or Secret key is included.
- Company ownership, membership roles, product publication/re-review, quotation commercial-term changes and verification decisions use narrowly scoped RPCs, triggers or existing column grants.
- Buyer request terms become immutable after a supplier quotation exists; closed/cancelled requests cannot be edited.
- Quotation status transitions are checked in a database trigger. Buyer decisions and supplier actions are distinct.
- Conversation attachments are stored in a private bucket and retrieved through short-lived signed URLs.
- Product images are intentionally public catalogue assets and are stored separately.
- Notification reads and updates are restricted to the owning user.

## Limitations / items requiring live verification

- Existing policies in a live Supabase project were not readable from this environment. Because permissive RLS policies combine with OR, inspect for older broad policies on `storage.objects`, `messages`, `conversations`, `company_members`, and `notifications` before production use.
- The new migration has not been executed against LIVE. Its SQL has been statically reviewed but not parsed/executed by a PostgreSQL server in this environment.
- Cross-company RLS, role escalation attempts, attachment path traversal, signed URL expiry, and concurrent quotation/request workflows require tests with two or more real test accounts.
- Invitation email delivery is not included. The token is displayed once to the authorized inviter; use a trusted channel and do not publish it.
- No user-facing read receipt is shown because the baseline migration explicitly revokes message update privileges and provides no read-receipt RPC.
- No verification document upload UI is included. Verification status review is admin-only.

## Operator checklist

1. Enable MFA for platform administrators.
2. Restrict Supabase Auth signup/SMTP and redirect settings to intended domains.
3. Confirm Storage policy set is least-privilege; no public policy may apply to `conversation-attachments`.
4. Keep database backups and review migrations before applying.
5. Rotate any credential if a Secret key was ever placed in a browser file or repository.
6. Monitor Supabase Auth, Postgres and Storage logs after enabling the new workflows.

## V1.0.1 pre-deployment corrections

The mandatory migration `202611040002_phase2_predeployment_security_fixes.sql` supersedes the earlier Storage and quotation-revision notes above: it drops known plural/singular legacy attachment policies, recreates exact-path private attachment policies, keeps product-image uploads/deletes manager-scoped, removes the forgeable quotation GUC, and adds a protected private transaction context for revisions. It also revokes client RFQ DML and buyer-request DELETE to prevent cascade deletion, and prevents an administrator from moderating/verifying their own company. See `SECURITY_PREDEPLOYMENT_AUDIT.md` for the independent findings and remaining live gates.
