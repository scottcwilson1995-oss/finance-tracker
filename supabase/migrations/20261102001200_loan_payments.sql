-- loan_payments: payments logged against manual loans (personal loans, Onity if manual).
-- Remaining balance and payoff date are calculated from these in the app.
create table public.loan_payments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade default auth.uid(),
  account_id uuid not null references public.accounts (id) on delete cascade,
  paid_on date not null,
  amount numeric(14, 2) not null check (amount > 0),
  note text,
  created_at timestamptz not null default now()
);

create index loan_payments_account_idx on public.loan_payments (account_id, paid_on desc);
create index loan_payments_user_idx on public.loan_payments (user_id);

alter table public.loan_payments enable row level security;

create policy "Users read their own loan payments"
  on public.loan_payments for select to authenticated
  using (user_id = auth.uid());

create policy "Users log payments on their manual accounts"
  on public.loan_payments for insert to authenticated
  with check (user_id = auth.uid() and private.owns_manual_account(account_id));

create policy "Users update payments on their manual accounts"
  on public.loan_payments for update to authenticated
  using (user_id = auth.uid() and private.owns_manual_account(account_id))
  with check (user_id = auth.uid() and private.owns_manual_account(account_id));

create policy "Users delete payments on their manual accounts"
  on public.loan_payments for delete to authenticated
  using (user_id = auth.uid() and private.owns_manual_account(account_id));
