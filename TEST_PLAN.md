# ZELQENTRA B2B — Phase 2.2 Activation & Integration Test Plan

**Status vocabulary:** PASS = executed and passed; FAIL = executed and failed; BLOCKED = requires the user's Supabase project/configuration or live accounts; NOT IMPLEMENTED = the user-facing feature/workflow does not exist. Static inspection is never reported as a live integration PASS.

## A. Local package checks

Run from the project directory:

```bash
node --check app.js
node --check backend.js
unzip -t NEW_BRAND_B2B_COMPLETE_REBRANDING_V1.zip
```

Also compare the table, column, RPC and view names referenced by `backend.js` with migrations 001–003. These checks can validate package integrity and JavaScript parsing only; they do not execute PostgreSQL or PostgREST.

## B. Supabase preflight

1. Create a fresh Supabase project.
2. Add only the Project URL and publishable/anon key to `supabase-config.js` (never a secret/service-role key).
3. Apply migrations 001, 002 and 003 in order.
4. Run `supabase/VALIDATION_QUERIES.sql` and inspect every result.
5. Enable Email Auth, set Site URL and allowed Redirect URLs, confirm the private `company-verification` bucket.
6. Serve the site over HTTPS or localhost HTTP and confirm the backend status badge.

## C. Create four independent test identities

Use separate email addresses you control. Prefer separate browser profiles/incognito sessions so sessions do not overwrite one another.

- **Buyer A** — signup as Buyer; company `Buyer A Trading`.
- **Supplier B** — signup as Supplier; company `Supplier B Manufacturing`.
- **Buyer C** — signup as Buyer; company `Buyer C Imports`. This second buyer is used to test private-data isolation.
- **Platform Admin** — a separate account, promoted only by the trusted project owner in Supabase SQL Editor. Never use the admin account for normal buyer/supplier tests.

For email-confirmation-enabled signup, confirm the email, return to the site and log in. The first confirmed login should call the workspace RPC and create the company plus initial owner membership in one transaction. Confirm one company membership exists for each test user.

## D. Authentication and workspace tests

| Test | Steps | Expected | Status before live project |
|---|---|---|---|
| Buyer signup | Register Buyer A and confirm email | Auth user and `public.users` profile with buyer role | BLOCKED |
| Supplier signup | Register Supplier B and confirm email | Profile role is supplier | BLOCKED |
| Company workspace | Log in after confirmation | One company and owner membership created atomically | BLOCKED |
| Idempotence | Log out/in twice | No duplicate company or owner membership | BLOCKED |
| Login/logout | Sign in, refresh, sign out | Session persists then is revoked | BLOCKED |
| Reset email | Request reset | Email arrives at allowed redirect | BLOCKED |
| Reset completion | Open email link | In-app password update flow | NOT IMPLEMENTED |
| Role escalation | Try signup metadata `platform_admin`, then update `users.role` from client | Role remains buyer/supplier; direct update denied | BLOCKED |

## E. Marketplace tests

1. As Supplier B, create a product through the service/API with status omitted. Expected inserted status is `pending_review`.
2. Attempt to insert a product with `status='published'` through the browser client. Expected: denied by RLS policy.
3. As admin, review and publish a test product through trusted SQL/admin tooling (admin moderation UI is not implemented).
4. Open the public homepage in a logged-out browser. Expected: published product and only safe company directory fields appear.
5. Search by product name and filter by category. Expected: filters operate on the live result set currently fetched (up to 60 records).
6. Temporarily use an invalid URL/key in a local test copy. Expected: `BACKEND ERROR · PREVIEW ONLY`, not sample cards presented as live listings.
7. Remove configuration in a separate local test copy. Expected: `DEMO MODE · SAMPLE DATA`.

| Operation | Expected | Status before live project |
|---|---|---|
| Published product read | Database records only | BLOCKED |
| Product detail page | Dedicated detail route/page | NOT IMPLEMENTED |
| Product insert/update/delete | Service methods and RLS; update cannot alter status/owner | BLOCKED |
| Product image upload/gallery | Full UI/storage workflow | NOT IMPLEMENTED |
| Search/category filter | Client filter over fetched live records | BLOCKED |
| Server-side pagination | Stable paginated search | NOT IMPLEMENTED |

## F. RFQ and quotation tests

1. As Buyer A, create an open buyer request and associated RFQ using the service method.
2. As Supplier B, retrieve open RFQs. Only open requests and non-expired RFQs should be returned.
3. As Supplier B, submit a quotation with status `submitted`.
4. As Buyer A, read the quotation attached to Buyer A's RFQ.
5. As Buyer C, try reading Buyer A's non-public request and quotation. Expected: no rows/permission denied.
6. As Supplier B, try changing quotation price/currency/quantity or supplier company through direct update. Expected: denied (only `status` column is granted).
7. As Supplier B, status may transition to `revised` or `withdrawn`; as Buyer A, status may transition to `accepted` or `rejected`. Other transitions should be rejected by the database trigger.

The RFQ composer, supplier submission form and quotation comparison UI are not implemented; these tests require invoking the prepared service methods from a controlled test harness or SQL/API client using the respective user's JWT. Do not use service-role credentials.

## G. Direct RLS/security matrix

Use each account's normal browser session/JWT. Test through direct Supabase client/API calls, not only by hiding UI controls.

| Attempt | Account | Expected result |
|---|---|---|
| Read Buyer C private/draft buyer requests | Buyer A | Denied/zero rows |
| Read Buyer A private requests/quotes | Buyer C | Denied/zero rows |
| Update Supplier B company/product as Buyer A | Buyer A | Denied |
| Update another company's membership role | Supplier B | Denied; membership writes are not granted to browser clients |
| Insert arbitrary owner membership | Buyer A | Denied; only workspace RPC creates initial owner |
| Change own `users.role` or `is_active` | Any normal user | Denied |
| Change product `status` to published | Supplier B | Denied |
| Change quotation price/currency/quantity | Supplier B or Buyer A | Denied |
| Change message `sender_id`/`conversation_id` | Any participant | Denied; message updates are revoked |
| Insert message with another sender ID | Any user | Denied by insert policy |
| Create conversation without managing either company | Any outsider | Denied |
| Read verification metadata/document | Unrelated user/anon | Denied |
| Upload document to another company's path | Supplier B | Denied |
| Invoke admin overview | Buyer A/Supplier B | `42501` forbidden |
| Invoke admin overview | Platform Admin | Metrics returned |
| Read public company directory | Logged-out visitor | Only safe fields returned |

Do not test with service-role key; it bypasses RLS. Record the exact operation, account role, response status/error code and whether rows were returned. Redact emails, IDs and project references before sharing logs.

## H. Storage tests

- Confirm bucket is private.
- As a company manager, upload a PDF/JPEG/PNG smaller than 10 MB under `<user-id>/<company-id>/<file>`.
- Try an unsupported MIME type and a file over 10 MB; browser helper should reject them.
- Try upload under another user's ID or another company's ID; expected denial.
- Try downloading as an unrelated account and as anonymous; expected denial.
- Confirm cleanup removes an uploaded object if document metadata insertion fails.

A browser MIME check is not file-signature validation or malware scanning. Those controls remain a production blocker.

## I. Regression checklist

| Phase 1.0 feature | Status / check |
|---|---|
| Homepage and sections | Existing HTML/CSS preserved; visual browser check pending |
| Header and anchor navigation | Test all links on desktop/mobile |
| Marketplace sample cards | Visible only in demo mode |
| Marketplace search/filter | Existing controls preserved; live mode replaces data source |
| Product preview/detail | Preview action exists; dedicated detail route NOT IMPLEMENTED |
| Responsive layout | Static files preserved; real Android visual check BLOCKED |
| Mobile navigation | Existing toggle/listeners preserved; real device check BLOCKED |

## J. Release gate

Do not mark backend activation PASS until all three migrations have executed in the target project, validation diagnostics are clean, signup/login/session and workspace creation pass, marketplace queries return real records or a truthful zero state, Storage is private, and every cross-account direct API test above passes. Missing screens remain NOT IMPLEMENTED even if database tables/services exist.
