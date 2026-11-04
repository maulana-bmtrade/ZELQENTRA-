# Changelog — Phase 2 Security Audit V1.0.1

- Added mandatory migration `202611040002_phase2_predeployment_security_fixes.sql`.
- Explicitly drops legacy plural and Phase 2 singular conversation attachment Storage policies before recreating least-privilege policies.
- Enforces exact conversation attachment object path shape, company membership, and uploader identity.
- Retains private conversation bucket and public-read-only product image bucket with manager-only upload/delete.
- Removed forgeable quotation revision custom-GUC authorization; added private transaction-scoped revision context.
- Reasserted status-only client update grants for quotations; commercial revisions use the RPC.
- Resolved pgcrypto extension schema dynamically for invitation token hashing.
- Revoked client-side RFQ DML and buyer-request DELETE to prevent re-parenting and cascade deletion of quotations.
- Added self-company restrictions to platform product moderation and company verification RPCs.
- Made notification trigger writes best-effort and re-created event triggers once.
- Added read-only SQL catalog validation queries and independent audit/QA reports.
- No database migration was executed against Supabase LIVE.
