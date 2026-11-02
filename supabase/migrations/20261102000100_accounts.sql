-- Accounts: checking, savings, credit cards, loans, investments, insurance.
-- Rows come from Plaid (server-side sync) or are entered manually.
create table public.accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade default auth.uid(),
  source text not null check (source in ('plaid', 'manual')),
  name text not null,
  type text not null check (type in ('cash', 'credit', 'loan', 'investment', 'insurance')),
  created_at timestamptz not null default now()
);

create index accounts_user_id_idx on public.accounts (user_id);

alter table public.accounts enable row level security;

create policy "Users manage their own accounts"
  on public.accounts
  for all
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
