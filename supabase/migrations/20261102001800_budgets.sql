-- budgets: one per user per month (dated the 1st). Lines (amount per category) are in budget_lines.
create table public.budgets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade default auth.uid(),
  month date not null check (extract(day from month) = 1),
  rollover boolean not null default false, -- carry unspent amounts into next month
  created_at timestamptz not null default now(),
  unique (user_id, month)
);

alter table public.budgets enable row level security;

create policy "Users read their own budgets"
  on public.budgets for select to authenticated using (user_id = auth.uid());
create policy "Users add their own budgets"
  on public.budgets for insert to authenticated with check (user_id = auth.uid());
create policy "Users update their own budgets"
  on public.budgets for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "Users delete their own budgets"
  on public.budgets for delete to authenticated using (user_id = auth.uid());
