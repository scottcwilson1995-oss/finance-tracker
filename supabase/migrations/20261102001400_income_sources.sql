-- income_sources: employer paychecks, side income, rental, interest/dividends, other.
create table public.income_sources (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade default auth.uid(),
  name text not null,
  kind text not null check (kind in ('employer', 'side', 'rental', 'interest', 'other')),
  expected_amount numeric(14, 2),
  frequency text not null check (frequency in ('weekly', 'biweekly', 'semi_monthly', 'monthly', 'quarterly', 'annually', 'one_time')),
  next_payday date,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create index income_sources_user_idx on public.income_sources (user_id);

alter table public.income_sources enable row level security;

create policy "Users read their own income sources"
  on public.income_sources for select to authenticated using (user_id = auth.uid());
create policy "Users add their own income sources"
  on public.income_sources for insert to authenticated with check (user_id = auth.uid());
create policy "Users update their own income sources"
  on public.income_sources for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "Users delete their own income sources"
  on public.income_sources for delete to authenticated using (user_id = auth.uid());
