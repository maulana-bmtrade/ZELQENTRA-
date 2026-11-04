# ZELQENTRA Phase 2 — Independent Pre-deployment Security Audit

**Audited package:** `ZELQENTRA_PHASE2_B2B_CORE_V1.0.0.zip`  
**Audit output:** `ZELQENTRA_PHASE2_B2B_CORE_V1.0.1_SECURITY_AUDITED.zip`  
**Scope:** source ZIP, all included HTML/JavaScript, baseline migrations 001–003, Phase 2 migration 040001, and corrective migration 040002.  
**Database mutation:** none. No SQL was executed against Supabase LIVE.

## Executive decision

**Status: BLOCKED for LIVE deployment approval.** The package contains concrete corrective changes for the identified source-level security defects, but the audit environment did not have a PostgreSQL parser/server or Supabase LIVE catalog connection. Therefore migration syntax/execution, actual deployed policy catalog, runtime role behavior, and two-company isolation cannot be certified. Apply only after a DBA reviews the SQL and runs the supplied validation queries against the intended project.

## Findings and remediation

| ID | Severity | Finding in V1.0.0 | Remediation in audited package | Status |
|---|---|---|---|---|
| SEC-01 | CRITICAL | Phase 2 dropped singular `conversation_attachment_*` names but did not drop the legacy plural `conversation_attachments_read` and `conversation_attachments_insert` names reported by the operator. A leftover permissive policy could OR-broaden Storage access. | Both plural and singular aliases are dropped; restrictive policies are recreated. | PASS (static fix); LIVE catalog BLOCKED |
| SEC-02 | CRITICAL | Conversation Storage path authorization cast arbitrary folder text to UUID and did not enforce the exact folder count. | Policies enforce exactly `<conversation UUID>/<uploader UUID>/<filename>`, validate UUID format before cast, require membership in either conversation company, and bind insert/delete to `auth.uid()`. | PASS (static fix) |
| SEC-03 | HIGH | `app.quotation_revision` custom GUC was used as an authorization bypass. An authenticated client can set custom GUC values. | GUC bypass removed. A private transaction-scoped context table with no client grants authorizes only the revision RPC. Direct client UPDATE remains status-only. | PASS (static fix) |
| SEC-04 | HIGH | `revise_quotation` had duplicate definitions and an unsafe intermediate implementation. | Final signature is singular and matches frontend arguments; protected context is inserted/deleted inside the SECURITY DEFINER RPC. | PASS (static consistency); SQL execution NOT TESTED |
| SEC-05 | HIGH | pgcrypto calls assumed functions were in `public`, which is not guaranteed on Supabase projects where extensions may be installed in `extensions`. | Invitation hashing resolves pgcrypto's installed extension schema from `pg_extension`; token entropy uses two UUIDs. | PASS (static fix); runtime NOT TESTED |
| SEC-06 | HIGH | Buyer request / RFQ delete paths could cascade-delete RFQs and quotations. | Client RFQ insert/update/delete privileges are revoked; RFQ creation is through controlled RPCs. Buyer-request DELETE is revoked. | PASS (static fix) |
| SEC-07 | MEDIUM | Notification insert errors could roll back the parent business operation. | Notification trigger writes are best-effort and catch/report errors as warnings. Trigger instances are recreated once per event. | PASS (static fix); runtime NOT TESTED |
| SEC-08 | HIGH | Platform admin moderation RPCs did not explicitly prevent an administrator from moderating/verifying a company to which the same account belongs. | Both moderation RPCs reject targets where the acting admin is a company member. | PASS (static fix) |
| SEC-09 | HIGH | Unknown policies in the actual live `storage.objects` catalog cannot be enumerated from the supplied migrations. | Added read-only catalog query that lists every Storage policy, not only matching policy names. | BLOCKED until LIVE catalog review |
| SEC-10 | HIGH | Legacy `NEXVORA_API.createBuyerRequest()` inserted a buyer request and then directly inserted an RFQ; the new least-privilege RFQ grants would reject the second operation and leave an orphan request. | Replaced with the atomic `publish_buyer_request_with_rfq(...)` RPC and reads back the created request/RFQ. | PASS (static fix) |

## Storage policy result

### Conversation attachments

The final intended policy behavior is:

- Bucket `conversation-attachments` is `public=false`.
- Reads: authenticated user must be a member of the buyer or supplier company attached to the conversation UUID in path segment 1.
- Inserts: authenticated user must be a member of that conversation and path segment 2 must equal their own `auth.uid()`.
- Deletes: same conversation membership check and uploader identity check.
- Path must contain exactly two folder segments before the filename.
- Allowed MIME types: PDF, JPEG, PNG; max size 10 MiB.
- No public or anonymous attachment policy is created.

Legacy policy names explicitly dropped:

- `conversation_attachments_read`
- `conversation_attachments_insert`
- `conversation_attachments_delete_own`
- `conversation_attachment_read`
- `conversation_attachment_insert`
- `conversation_attachment_delete_own`

**Important:** this only proves the migration removes known names. Any differently named permissive policy already present in the LIVE catalog could still OR-broaden access. Run query C and E in `supabase/PHASE2_VALIDATION_QUERIES.sql`; deployment remains BLOCKED until all rows are understood.

### Product images

- Bucket `product-images` remains public-readable by design for catalogue images.
- Upload and delete require the company UUID in path segment 1 and `public.is_company_manager(company_id)`.
- Only one folder segment is accepted; MIME allow-list is JPEG/PNG/WebP and max size is 5 MiB.
- Public-read is not public-write. Do not store private company documents or correspondence in this bucket.

## SQL and schema compatibility review

The audit compared Phase 2 references against the supplied baseline definitions:

- `company_member_role`: `owner`, `admin`, `member`.
- `product_status`: `draft`, `pending_review`, `published`, `rejected`, `archived`.
- `rfq_status`: `draft`, `open`, `closed`, `cancelled`.
- `quotation_status`: `submitted`, `revised`, `accepted`, `rejected`, `withdrawn`.
- `verification_status`: `not_submitted`, `pending`, `verified`, `rejected`.
- `buyer_requests.id` → `rfqs.buyer_request_id` (unique FK).
- `rfqs.id` → `quotations.rfq_id`.
- `conversations.id` → `messages.conversation_id`.
- `company_invitations.company_id` → `companies.id`; `invited_by` → `users.id`.
- `quotation_status_history.quotation_id` → `quotations.id`.

The Phase 2 migration adds `quotations.minimum_order_quantity` with a non-negative check and does not drop baseline tables or disable RLS. RFQ and buyer-request client deletion are further restricted in migration 040002 to prevent cascading removal of supplier quotations.

## SECURITY DEFINER review

The included SECURITY DEFINER functions use an empty `search_path` setting and schema-qualified application objects. The invitation token hash helper resolves the pgcrypto extension schema dynamically. Trigger-only functions have EXECUTE revoked from `public`, `anon`, and `authenticated`. RPCs intended for authenticated clients have explicit grants and internal actor/role checks.

The quotation revision context table is in `private`, has no client grants, and is transaction/backend/quotation/actor scoped. The revision RPC deletes its context row before returning; transaction rollback also rolls back the context row. Direct browser updates cannot modify commercial columns.

## Frontend-to-database consistency

All 15 literal `.rpc()` call sites found in the JavaScript source resolve to a function definition in the included baseline or Phase 2 migrations. The legacy buyer-request helper was also changed to use the atomic request/RFQ RPC rather than direct RFQ insertion. Auth recovery now handles the `PASSWORD_RECOVERY` event and updates the password after confirmation; the prompt-based flow still requires browser testing. Key argument names checked include `p_company_name`, `p_member_id`, `p_role`, `p_company_id`, `p_email`, `p_token`, `p_request_id`, `p_product_id`, `p_status`, `p_quotation_id`, `p_unit_price`, `p_currency`, `p_quantity`, `p_minimum_order_quantity`, `p_lead_time_days`, `p_validity_date`, and `p_notes`.

Direct table operations were reviewed against baseline grants/RLS and Phase 2 additions. Quotation status changes remain direct status-only updates; commercial revisions use `revise_quotation`. Messaging uses baseline participant RLS. Attachment upload path matches the final Storage policy.

## Required live DBA checks before approval

1. Confirm migrations 001–003 are already applied to the exact project.
2. Back up the database.
3. Apply `202611040001_phase2_core.sql` followed immediately by `202611040002_phase2_predeployment_security_fixes.sql` in a controlled maintenance window.
4. Run every query in `supabase/PHASE2_VALIDATION_QUERIES.sql`.
5. Confirm no unknown permissive policy grants attachment access to `anon` or unrelated `authenticated` users.
6. Test with two independent companies and at least owner/admin/member accounts.
7. Verify the `private` schema is not exposed through PostgREST and the revision context table has no grants to `anon`/`authenticated`.
8. Test all quotation transitions and attempt direct commercial-column updates (must fail).
9. Test that buyer-request/RFQ DELETE from authenticated clients fails.
10. Verify notification errors do not abort the parent insert/update.

## Scope limitations

- No Supabase LIVE connection was available in this audit environment.
- No PostgreSQL server/client or PostgreSQL grammar parser was available; full server-side SQL parse/execute is NOT TESTED.
- The supplied baseline migrations are the source of truth for static comparison; actual live schema drift is BLOCKED pending catalog output.
- No two-company runtime RLS, Storage upload/download, Auth, or browser end-to-end tests were executed.
- No SQL was applied to LIVE.
