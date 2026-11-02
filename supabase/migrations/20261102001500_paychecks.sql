-- paychecks: one per pay date (monthly pay: period = calendar month, pay date the
-- following 5th; tax-year totals follow the pay date). The detailed breakdown is
-- in paycheck_lines. deposit_transaction_id matches the bank deposit.
create table public.paychecks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade default auth.uid(),
  income_source_id uuid references public.income_sources (id) on delete set null,
  pay_date date not null,
  period_start date,
  period_end date,
  gross numeric(14, 2) not null check (gross >= 0),
  net numeric(14, 2) not null,
  deposit_transaction_id uuid references public.transactions (id) on delete set null,
  created_at timestamptz not null default now(),
  unique (income_source_id, pay_date)
);

create index paychecks_user_idx on public.paychecks (user_id, pay_date desc);

alter table public.paychecks enable row level security;

create policy "Users read their own paychecks"
  on public.paychecks for select to authenticated using (user_id = auth.uid());

create policy "Users add their own paychecks"
  on public.paychecks for insert to authenticated
  with check (
    user_id = auth.uid()
    and (income_source_id is null or exists (
      select 1 from public.income_sources s where s.id = income_source_id and s.user_id = auth.uid()))
    and (deposit_transaction_id is null or exists (
      select 1 from public.transactions t where t.id = deposit_transaction_id and t.user_id = auth.uid()))
  );

create policy "Users update their own paychecks"
  on public.paychecks for update to authenticated
  using (user_id = auth.uid())
  with check (
    user_id = auth.uid()
    and (income_source_id is null or exists (
      select 1 from public.income_sources s where s.id = income_source_id and s.user_id = auth.uid()))
    and (deposit_transaction_id is null or exists (
      select 1 from public.transactions t where t.id = deposit_transaction_id and t.user_id = auth.uid()))
  );

create policy "Users delete their own paychecks"
  on public.paychecks for delete to authenticated using (user_id = auth.uid());
