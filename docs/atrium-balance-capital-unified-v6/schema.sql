-- Atrium Balance Capital Unified v6
-- PostgreSQL schema focused on:
-- 1) SEC EDGAR ingestion
-- 2) Read-only brokerage connectivity (including Robinhood)
-- 3) Immutable auditability

create extension if not exists "pgcrypto";

create table if not exists users (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  full_name text,
  created_at timestamptz not null default now()
);

create table if not exists broker_connections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
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

create table if not exists holdings_snapshot (
  id uuid primary key default gen_random_uuid(),
  broker_connection_id uuid not null references broker_connections(id) on delete cascade,
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

create table if not exists transactions_snapshot (
  id uuid primary key default gen_random_uuid(),
  broker_connection_id uuid not null references broker_connections(id) on delete cascade,
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

create table if not exists sec_companies (
  cik text primary key,
  ticker text,
  company_name text not null,
  sic text,
  sic_description text,
  ein text,
  state_of_incorporation text,
  updated_at timestamptz not null default now()
);

create table if not exists sec_filings (
  id uuid primary key default gen_random_uuid(),
  cik text not null references sec_companies(cik) on delete cascade,
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

create table if not exists sec_facts (
  id uuid primary key default gen_random_uuid(),
  cik text not null references sec_companies(cik) on delete cascade,
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

create index if not exists idx_holdings_snapshot_connection_date
  on holdings_snapshot (broker_connection_id, as_of_date desc);

create index if not exists idx_transactions_snapshot_connection_trade_date
  on transactions_snapshot (broker_connection_id, trade_date desc);

create index if not exists idx_sec_filings_cik_date
  on sec_filings (cik, filing_date desc);

create index if not exists idx_sec_facts_cik_tag_unit
  on sec_facts (cik, tag, unit);

create table if not exists sync_jobs (
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

create table if not exists audit_events (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references users(id),
  event_type text not null,
  entity_name text not null,
  entity_id text not null,
  event_payload jsonb not null,
  created_at timestamptz not null default now()
);
