-- holdings: investment positions. Plaid-linked accounts: server-written. Manual accounts: app-written.
create table public.holdings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade default auth.uid(),
  account_id uuid not null references public.accounts (id) on delete cascade,
  security_name text not null,
  ticker text,
  quantity numeric(20, 6) not null,
  cost_basis numeric(14, 2),
  value numeric(14, 2) not null,
  as_of date not null,
  created_at timestamptz not null default now()
);

create index holdings_user_idx on public.holdings (user_id);
create index holdings_account_idx on public.holdings (account_id);

alter table public.holdings enable row level security;

create policy "Users read their own holdings"
  on public.holdings for select to authenticated
  using (user_id = auth.uid());

create policy "Users add holdings to their manual accounts"
  on public.holdings for insert to authenticated
  with check (user_id = auth.uid() and private.owns_manual_account(account_id));

create policy "Users update holdings of their manual accounts"
  on public.holdings for update to authenticated
  using (user_id = auth.uid() and private.owns_manual_account(account_id))
  with check (user_id = auth.uid() and private.owns_manual_account(account_id));

create policy "Users delete holdings of their manual accounts"
  on public.holdings for delete to authenticated
  using (user_id = auth.uid() and private.owns_manual_account(account_id));
