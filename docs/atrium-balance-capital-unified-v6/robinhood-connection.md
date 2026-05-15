# Robinhood Connection (Read-Only, Supabase)

## Goal
Enable users to connect Robinhood accounts and view balances/holdings/transactions **without any ability to trade or edit brokerage fields**.

## Recommended integration path
Because direct Robinhood developer access can vary, use a brokerage aggregation provider (for example Plaid Investments) and route all sync through secure server-side workers.

## Architecture pattern
1. User signs in with Supabase Auth.
2. Client starts `/api/v6/brokers/robinhood/connect` handshake.
3. Edge Function exchanges the provider token and persists encrypted credentials in `broker_connections`.
4. Scheduled sync worker pulls account data and writes **snapshots only**:
   - `holdings_snapshot`
   - `transactions_snapshot`
5. Client queries read-only rows through RLS-protected tables/views.

## Non-negotiable controls
- `broker_connections.read_only` must stay `true`.
- No client credentials for any brokerage provider.
- No order/trade routes in your API surface.
- Only service-role jobs may write snapshot tables.
- Authenticated users get `SELECT` access only to their own data through RLS.

## Suggested API surface
- `POST /api/v6/brokers/robinhood/connect` (handshake only)
- `GET /api/v6/brokers`
- `GET /api/v6/portfolio/holdings?asOf=YYYY-MM-DD`
- `GET /api/v6/portfolio/transactions?from=YYYY-MM-DD&to=YYYY-MM-DD`
- `GET /api/v6/portfolio/performance`

## Operational guidance
- Incremental sync every 15-60 minutes.
- Daily position/equity reconciliation.
- On token refresh failure: set `status='error'`, log `sync_jobs`, notify user.
