# Atrium Balance Capital Unified v6 (Supabase)

This package provides a **Supabase-first** foundation:
1. PostgreSQL schema for unified investment data.
2. Read-only Robinhood connectivity pattern.
3. SEC EDGAR ingestion design (free source).
4. Free and paid market/financial data alternatives.

## Included files
- `schema.sql` — core relational schema + RLS policies for Supabase.
- `robinhood-connection.md` — secure read-only Robinhood connection workflow.
- `edgar-integration.md` — SEC EDGAR ingestion plan.
- `data-sources/free-databases.md` — free alternatives.
- `data-sources/paid-options.md` — paid premium options.

## Implementation order (Supabase)
1. Create a Supabase project and run `schema.sql` as a migration.
2. Use Supabase Auth for user identity (`auth.users` -> `public.users`).
3. Implement broker auth/token vault integration in an Edge Function.
4. Build scheduled Edge Functions for brokerage snapshot sync and EDGAR ingestion.
5. Expose only read-side endpoints for holdings/transactions/performance.

## Security baseline
- Store broker tokens encrypted at rest (KMS or Supabase Vault pattern).
- Enforce `read_only=true` on all broker connection rows.
- Do not implement order placement endpoints.
- Keep client access read-only to snapshot and SEC views.
- Log sync/user access events in `audit_events`.
