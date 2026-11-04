# Changelog — Phase 2 Core

## V1.0.0

- Added authenticated company workspace and profile/team management.
- Added hashed company invitation tokens, accept flow and owner/admin member management RPCs.
- Added company-scoped product CRUD, product image upload and pending-review lifecycle.
- Added buyer request and RFQ workflow, including atomic request/RFQ creation.
- Added supplier quotation submission/revision/withdrawal, buyer accept/reject and status history.
- Added buyer-supplier conversations, messages and private PDF/JPEG/PNG attachment support.
- Added event-driven notifications and unread/read UI.
- Added platform-admin dashboard, product moderation and company verification RPCs.
- Added additive Supabase migration, setup/security/QA documentation and validation queries.
- Preserved the existing public Marketplace and Company Directory implementation.

## Explicitly deferred

- SMTP/Edge Function invitation email delivery.
- Message read receipts.
- Verification document upload and review attachment UI.
- Payments, escrow, invoices, shipping execution and AI matching.
- Live migration execution and end-to-end QA pending owner authorization and reachable Supabase environment.
