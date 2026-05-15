const state = { url: '', key: '', jwt: '' };

const endpoints = {
  brokers: 'broker_connections?select=id,broker_name,display_name,status,read_only,last_synced_at,created_at&order=created_at.desc',
  holdings: 'holdings_snapshot?select=as_of_date,symbol,asset_name,quantity,market_price,market_value,currency&order=as_of_date.desc&limit=100',
  transactions: 'transactions_snapshot?select=trade_date,settle_date,symbol,activity_type,quantity,price,amount,currency&order=trade_date.desc&limit=100',
  filings: 'sec_filings?select=filing_date,form,cik,accession_number,filing_url&order=filing_date.desc&limit=100',
  facts: 'sec_facts?select=cik,taxonomy,tag,unit,period_end,value,filed_at,form&order=filed_at.desc&limit=100',
  audit: 'audit_events?select=event_type,entity_name,entity_id,created_at&order=created_at.desc&limit=100',
};

function setStatus(msg) { document.getElementById('status').textContent = msg; }

async function fetchTable(name) {
  if (!state.url || !state.key || !state.jwt) {
    setStatus('Please connect first.');
    return;
  }
  const res = await fetch(`${state.url}/rest/v1/${endpoints[name]}`, {
    headers: {
      apikey: state.key,
      Authorization: `Bearer ${state.jwt}`,
      'Content-Type': 'application/json',
    },
  });
  const text = await res.text();
  document.getElementById(name).textContent = `${res.status} ${res.statusText}\n${text}`;
}

document.getElementById('config-form').addEventListener('submit', (e) => {
  e.preventDefault();
  state.url = document.getElementById('supabase-url').value.replace(/\/$/, '');
  state.key = document.getElementById('supabase-key').value.trim();
  state.jwt = document.getElementById('supabase-jwt').value.trim();
  setStatus('Connected. Use Load buttons to query read-only data.');
});

document.querySelectorAll('button[data-load]').forEach((btn) => {
  btn.addEventListener('click', () => fetchTable(btn.dataset.load));
});
