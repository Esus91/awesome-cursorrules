# Robinhood Connection (Read-Only)

## Goal
Enable users to connect Robinhood accounts and view balances/holdings/transactions **without any ability to trade or edit brokerage data**.

## Architecture pattern
1. User authenticates through a broker aggregation partner or direct OAuth flow (if available in your Robinhood access channel).
2. App stores encrypted access/refresh tokens in `broker_connections`.
3. A sync worker reads brokerage endpoints and writes snapshots only:
   - `holdings_snapshot`
   - `transactions_snapshot`
4. UI only reads snapshot tables.

## Non-negotiable controls
- `broker_connections.read_only` must remain `true`.
- Never store trade endpoints in client-accessible config.
- API routes expose only `GET` methods for brokerage resources.
- Service policy denies HTTP methods `POST/PUT/PATCH/DELETE` to any trade/order path.

## Suggested API endpoints (server-side)
- `GET /api/v6/brokers`
- `POST /api/v6/brokers/robinhood/connect` (connect handshake only)
- `GET /api/v6/portfolio/holdings?asOf=YYYY-MM-DD`
- `GET /api/v6/portfolio/transactions?from=YYYY-MM-DD&to=YYYY-MM-DD`
- `GET /api/v6/portfolio/performance`

## Token handling
- Encrypt tokens with a KMS-backed key.
- Rotate keys quarterly.
- Mark connection `status='error'` when token refresh fails.
- Track sync attempts in `sync_jobs`.

## Data flow
- Full sync on initial connect.
- Incremental sync every 15-60 minutes for brokerage transactions.
- Daily reconciliation against account equity/positions.

## What “view-only” means in practice
- Your database is treated as a projection cache of brokerage state.
- Users cannot mutate imported rows from the UI.
- Manual corrections require admin-only out-of-band tooling + audit events.
