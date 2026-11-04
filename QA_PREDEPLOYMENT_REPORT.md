# ZELQENTRA Phase 2 V1.0.1 — Pre-deployment QA Report

## Package and integrity

- Baseline: user-supplied `ZELQENTRA_PHASE2_B2B_CORE_V1.0.0.zip`.
- Input ZIP checksum sidecar matched the actual input SHA-256.
- Input ZIP integrity: PASS; 89 entries, no corrupt member.
- Output package includes source corrections, migrations 040001/040002, SQL validation queries and audit documentation.
- No SQL was executed against Supabase LIVE.

## Static checks

| Check | Status | Evidence |
|---|---|---|
| Input ZIP integrity | PASS | Python `zipfile.testzip()` returned `None`. |
| Input SHA-256 sidecar | PASS | Sidecar matched actual input hash. |
| JavaScript syntax | PASS | Node.js v22 `node --check` across all JS files. |
| HTML parsing | PASS | 9 HTML pages parsed. |
| Local HTML references | PASS | No missing local `href`/`src` targets. |
| Duplicate HTML IDs | PASS | No duplicate IDs found. |
| Relative JS imports | PASS | All relative import targets exist. |
| CSS structural check | PASS | No unbalanced braces. |
| RPC name-to-definition check | PASS (static) | All 14 literal frontend RPC call sites map to a function definition in supplied migrations. |
| Baseline schema references | PASS (static) | Tables, enums, columns and FK paths checked against baseline SQL. |
| Storage policy corrections | PASS (static) | Legacy names dropped and intended policies recreated in migration 040002. |
| Quotation GUC bypass | PASS (static fix) | No executable `app.quotation_revision` GUC use remains in final migration set. |
| SECURITY DEFINER search_path | PASS (static) | Functions inspected use `search_path=''`; no dynamic user-controlled search path found. |
| Secret credential scan | PASS | No Supabase Secret/service_role key pattern found. Public Publishable key is expected in browser config. |
| Full PostgreSQL SQL parse | NOT TESTED | No PostgreSQL parser/server available; lexical/dollar-quote checks only. |
| Production build | NOT APPLICABLE | Static HTML/CSS/Vanilla JS site; no build pipeline. |

## Runtime / live checks

| Check | Status | Reason |
|---|---|---|
| Supabase LIVE schema catalog comparison | BLOCKED | No live DB connection. |
| Apply migrations 040001/040002 | NOT TESTED | Explicitly not executed. |
| Storage policy OR-combination on LIVE | BLOCKED | Unknown policies may exist outside supplied baseline. |
| Auth signup/login/reset | NOT TESTED | Requires live Supabase Auth. |
| Product CRUD and image upload | NOT TESTED | Requires live project and company accounts. |
| Buyer request/RFQ/quotation workflow | NOT TESTED | Requires live DB and buyer/supplier accounts. |
| Quotation direct-update denial | NOT TESTED | Requires database runtime test. |
| Messaging and attachment access | NOT TESTED | Requires two-company live test. |
| Cross-company RLS | BLOCKED | No independent live test accounts/project access. |
| Role escalation / self-moderation | NOT TESTED | Requires runtime calls under multiple roles. |
| Notification trigger behavior | NOT TESTED | Requires database execution. |
| Browser responsive QA | NOT TESTED | No browser/device automation executed. |

## Release decision

**BLOCKED for LIVE deployment approval.** Static source-level corrections are packaged, but do not apply to production until a DBA runs the migrations in order, inspects all live Storage policies, and completes the two-company RLS/Storage workflow tests. A syntactically balanced SQL file is not evidence of successful PostgreSQL execution.
