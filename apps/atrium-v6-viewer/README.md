# Atrium v6 Viewer App (Supabase)

Minimal read-only web app to view:
- broker connections
- holdings snapshots
- transactions snapshots
- SEC filings/facts
- audit events

## Run
From this directory:

```bash
python -m http.server 4173
```

Open `http://localhost:4173` and enter:
1. Supabase project URL
2. Supabase anon key
3. User access JWT (from Supabase Auth)

This app reads from Supabase REST (`/rest/v1`) and respects RLS policies from `docs/atrium-balance-capital-unified-v6/schema.sql`.
