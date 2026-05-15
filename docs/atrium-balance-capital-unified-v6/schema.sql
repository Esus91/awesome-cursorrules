-- Atrium Balance Capital Unified v6 (Supabase/PostgreSQL)
-- Focus:
-- 1) SEC EDGAR ingestion
-- 2) Read-only brokerage connectivity (including Robinhood)
-- 3) Immutable auditability with Supabase RLS

create extension if not exists "pgcrypto";

-- Profiles are keyed to Supabase Auth users.
create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  full_name text,
  created_at timestamptz not null default now()
);

create table if not exists public.broker_connections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  broker_name text not null check (broker_name in ('robinhood','schwab','fidelity','interactive_brokers','other')),
  external_account_id text not null,
  display_name text,
  status text not null default 'active' check (status in ('active','revoked','error','pending')),
  read_only boolean not null default true,
  token_encrypted text not null,
  refresh_token_encrypted text,
  token_expires_at timestamptz,
  last_synced_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, broker_name, external_account_id)
);

create table if not exists public.holdings_snapshot (
  id uuid primary key default gen_random_uuid(),
  broker_connection_id uuid not null references public.broker_connections(id) on delete cascade,
  as_of_date date not null,
  symbol text not null,
  asset_name text,
  asset_type text,
  quantity numeric(20,8) not null,
  average_cost numeric(20,8),
  market_price numeric(20,8),
  market_value numeric(20,8),
  currency text not null default 'USD',
  source_hash text not null,
  created_at timestamptz not null default now(),
  unique (broker_connection_id, as_of_date, symbol)
);

create table if not exists public.transactions_snapshot (
  id uuid primary key default gen_random_uuid(),
  broker_connection_id uuid not null references public.broker_connections(id) on delete cascade,
  external_transaction_id text not null,
  trade_date date,
  settle_date date,
  symbol text,
  activity_type text not null,
  quantity numeric(20,8),
  price numeric(20,8),
  amount numeric(20,8),
  fees numeric(20,8),
  currency text not null default 'USD',
  raw_payload jsonb not null,
  created_at timestamptz not null default now(),
  unique (broker_connection_id, external_transaction_id)
);

create table if not exists public.sec_companies (
  cik text primary key,
  ticker text,
  company_name text not null,
  sic text,
  sic_description text,
  ein text,
  state_of_incorporation text,
  updated_at timestamptz not null default now()
);

create table if not exists public.sec_filings (
  id uuid primary key default gen_random_uuid(),
  cik text not null references public.sec_companies(cik) on delete cascade,
  accession_number text not null,
  filing_date date not null,
  report_date date,
  form text not null,
  primary_document text,
  filing_url text,
  accepted_at timestamptz,
  raw_index_payload jsonb not null,
  created_at timestamptz not null default now(),
  unique (cik, accession_number)
);

create table if not exists public.sec_facts (
  id uuid primary key default gen_random_uuid(),
  cik text not null references public.sec_companies(cik) on delete cascade,
  taxonomy text not null,
  tag text not null,
  unit text not null,
  period_start date,
  period_end date,
  value numeric,
  filed_at date,
  accession_number text,
  form text,
  frame text,
  source_payload jsonb not null,
  created_at timestamptz not null default now()
);

create table if not exists public.sync_jobs (
  id uuid primary key default gen_random_uuid(),
  source text not null check (source in ('robinhood','edgar')),
  source_ref text not null,
  status text not null check (status in ('queued','running','success','error')),
  started_at timestamptz,
  finished_at timestamptz,
  error_message text,
  metadata jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.audit_events (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references public.users(id),
  event_type text not null,
  entity_name text not null,
  entity_id text not null,
  event_payload jsonb not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_holdings_snapshot_connection_date
  on public.holdings_snapshot (broker_connection_id, as_of_date desc);

create index if not exists idx_transactions_snapshot_connection_trade_date
  on public.transactions_snapshot (broker_connection_id, trade_date desc);

create index if not exists idx_sec_filings_cik_date
  on public.sec_filings (cik, filing_date desc);

create index if not exists idx_sec_facts_cik_tag_unit
  on public.sec_facts (cik, tag, unit);

-- RLS for Supabase
alter table public.users enable row level security;
alter table public.broker_connections enable row level security;
alter table public.holdings_snapshot enable row level security;
alter table public.transactions_snapshot enable row level security;
alter table public.sec_companies enable row level security;
alter table public.sec_filings enable row level security;
alter table public.sec_facts enable row level security;
alter table public.sync_jobs enable row level security;
alter table public.audit_events enable row level security;

-- App users can only read/write their own profile row.
create policy "users_self_select" on public.users
for select using (auth.uid() = id);
create policy "users_self_update" on public.users
for update using (auth.uid() = id) with check (auth.uid() = id);

-- Brokerage connection ownership.
create policy "broker_connections_owner_select" on public.broker_connections
for select using (auth.uid() = user_id);
create policy "broker_connections_owner_insert" on public.broker_connections
for insert with check (auth.uid() = user_id and read_only = true);
create policy "broker_connections_owner_update" on public.broker_connections
for update using (auth.uid() = user_id) with check (auth.uid() = user_id and read_only = true);

-- Snapshot reads only for owners; no client-side writes.
create policy "holdings_owner_select" on public.holdings_snapshot
for select using (
  exists (
    select 1 from public.broker_connections bc
    where bc.id = holdings_snapshot.broker_connection_id
      and bc.user_id = auth.uid()
  )
);
create policy "transactions_owner_select" on public.transactions_snapshot
for select using (
  exists (
    select 1 from public.broker_connections bc
    where bc.id = transactions_snapshot.broker_connection_id
      and bc.user_id = auth.uid()
  )
);

-- SEC tables are read-only to authenticated users.
create policy "sec_companies_read_authenticated" on public.sec_companies
for select to authenticated using (true);
create policy "sec_filings_read_authenticated" on public.sec_filings
for select to authenticated using (true);
create policy "sec_facts_read_authenticated" on public.sec_facts
for select to authenticated using (true);

-- Jobs and audit events are readable by owners/admin paths only.
create policy "sync_jobs_owner_select" on public.sync_jobs
for select using (source_ref = auth.uid()::text);
create policy "audit_events_owner_select" on public.audit_events
for select using (actor_user_id = auth.uid());
