# Atrium Balance Capital Unified v6: Database + Read-Only Robinhood Integration

This package provides:
1. A PostgreSQL schema for unified investment data.
2. A read-only brokerage integration pattern (including Robinhood).
3. SEC EDGAR ingestion design (free source).
4. Free and paid market/financial data alternatives.

## Included files
- `schema.sql` — core relational schema.
- `robinhood-connection.md` — secure read-only Robinhood connection workflow.
- `edgar-integration.md` — SEC EDGAR ingestion plan.
- `data-sources/free-databases.md` — free alternatives.
- `data-sources/paid-options.md` — paid premium options.

## Implementation order
1. Apply `schema.sql` in PostgreSQL 14+.
2. Implement broker auth/token vault integration.
3. Build nightly sync workers for brokerage snapshots.
4. Build SEC EDGAR ingestion workers.
5. Expose read-only API endpoints for UI consumption.

## Security baseline
- Store broker tokens encrypted at rest.
- Keep `read_only=true` in broker connection records.
- Do not implement order placement endpoints.
- Log all sync and user-view actions in `audit_events`.
- Restrict database roles so app service account has no DDL permissions.
