# SEC EDGAR API Integration (Free)

Reference: https://www.sec.gov/developer

## Core datasets to ingest
1. Company tickers + CIK mapping.
2. Submissions feed (latest filings by CIK).
3. Company facts (XBRL fundamentals).

## Suggested ingestion jobs

### Job A — Company master sync (daily)
- Pull ticker/CIK mapping.
- Upsert into `sec_companies`.

### Job B — Filings sync (every 6-12 hours)
- For tracked CIKs, request submission index.
- Upsert filing metadata into `sec_filings`.

### Job C — Facts sync (daily/weekly)
- Pull company facts for tracked CIKs.
- Flatten units/taxonomies into `sec_facts`.

## Required request hygiene
- Send a descriptive `User-Agent` header with contact email.
- Respect SEC rate/access guidelines.
- Retry with exponential backoff on 429/5xx.

## Example extraction targets
- Revenue, net income, assets, liabilities, cash flow values.
- 10-K / 10-Q filing timelines.
- Historical restatements by accession.

## Serving EDGAR in the app
- Join holdings symbols -> issuer CIK mapping.
- Show latest filing date and form alongside each holding.
- Compute simple valuation overlays using selected `sec_facts` tags.
