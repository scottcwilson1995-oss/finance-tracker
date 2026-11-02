-- liabilities: credit card / mortgage / loan details for an account (1:1).
-- Plaid-linked accounts: written by the server. Manual accounts (Onity, personal
-- loans in either direction): written by the app.
create table public.liabilities (
  account_id uuid primary key references public.accounts (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade default auth.uid(),
  kind text not null check (kind in ('credit_card', 'mortgage', 'student_loan', 'personal_loan', 'other')),
  direction text not null default 'owe' check (direction in ('owe', 'owed_to_me')),
  other_party text,
  original_amount numeric(14, 2),
  interest_rate numeric(7, 4) check (interest_rate >= 0), -- percent; 0 is allowed
  start_date date,
  statement_balance numeric(14, 2),
  minimum_payment numeric(14, 2),
  payment_amount numeric(14, 2),
  payment_frequency text check (payment_frequency in ('weekly', 'biweekly', 'semi_monthly', 'monthly', 'quarterly', 'annually')),
  next_due_date date,
  updated_at timestamptz not null default now()
);

create index liabilities_user_idx on public.liabilities (user_id);
create index liabilities_due_idx on public.liabilities (user_id, next_due_date);

alter table public.liabilities enable row level security;

create policy "Users read their own liabilities"
  on public.liabilities for select to authenticated
  using (user_id = auth.uid());

create policy "Users add liabilities to their manual accounts"
  on public.liabilities for insert to authenticated
  with check (user_id = auth.uid() and private.owns_manual_account(account_id));

create policy "Users update liabilities of their manual accounts"
  on public.liabilities for update to authenticated
  using (user_id = auth.uid() and private.owns_manual_account(account_id))
  with check (user_id = auth.uid() and private.owns_manual_account(account_id));

create policy "Users delete liabilities of their manual accounts"
  on public.liabilities for delete to authenticated
  using (user_id = auth.uid() and private.owns_manual_account(account_id));
