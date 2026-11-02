-- recurring_streams: detected or manual recurring charges and income.
-- Server (service_role) writes source 'plaid' / 'detected'. The app can add manual
-- streams, confirm / dismiss / relabel any of its own, and delete only manual ones.
create table public.recurring_streams (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade default auth.uid(),
  account_id uuid references public.accounts (id) on delete set null,
  merchant text not null,
  direction text not null check (direction in ('outflow', 'inflow')),
  frequency text not null check (frequency in ('weekly', 'biweekly', 'semi_monthly', 'monthly', 'quarterly', 'annually', 'irregular')),
  average_amount numeric(14, 2) not null,
  last_date date,
  next_date date,
  status text not null default 'pending' check (status in ('pending', 'confirmed', 'dismissed')),
  source text not null check (source in ('plaid', 'detected', 'manual')),
  expense_type text check (expense_type in ('fixed', 'variable')),
  created_at timestamptz not null default now()
);

create index recurring_streams_user_idx on public.recurring_streams (user_id, status);
create index recurring_streams_next_idx on public.recurring_streams (user_id, next_date);

alter table public.recurring_streams enable row level security;

create policy "Users read their own recurring streams"
  on public.recurring_streams for select to authenticated
  using (user_id = auth.uid());

create policy "Users add manual recurring streams"
  on public.recurring_streams for insert to authenticated
  with check (
    user_id = auth.uid() and source = 'manual'
    and (account_id is null or private.owns_account(account_id))
  );

create policy "Users update their own recurring streams"
  on public.recurring_streams for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid() and (account_id is null or private.owns_account(account_id)));

create policy "Users delete their manual recurring streams"
  on public.recurring_streams for delete to authenticated
  using (user_id = auth.uid() and source = 'manual');
