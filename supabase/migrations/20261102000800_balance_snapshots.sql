-- balance_snapshots: one balance per account per day, for net worth history.
-- Written only by server-side jobs (service_role); the app reads its own.
create table public.balance_snapshots (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  account_id uuid not null references public.accounts (id) on delete cascade,
  snapshot_on date not null,
  balance numeric(14, 2) not null,
  created_at timestamptz not null default now(),
  unique (account_id, snapshot_on)
);

create index balance_snapshots_user_day_idx on public.balance_snapshots (user_id, snapshot_on desc);

alter table public.balance_snapshots enable row level security;

create policy "Users read their own balance snapshots"
  on public.balance_snapshots for select to authenticated
  using (user_id = auth.uid());

revoke insert, update, delete on public.balance_snapshots from authenticated, anon;
