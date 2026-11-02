-- transactions: one row per bank/manual transaction.
-- Sign convention follows Plaid: positive amount = money out, negative = money in.
-- Categorization order: manual edit > user rule > Plaid. The original Plaid
-- category is always kept in plaid_category so edits can be undone.
create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade default auth.uid(),
  account_id uuid not null references public.accounts (id) on delete cascade,
  plaid_transaction_id text unique,
  posted_on date not null,
  amount numeric(14, 2) not null,
  merchant text,
  description text,
  plaid_category text,
  category_id uuid references public.categories (id) on delete set null,
  category_source text not null default 'plaid' check (category_source in ('plaid', 'rule', 'manual')),
  expense_type text check (expense_type in ('fixed', 'variable')), -- per-transaction override
  created_at timestamptz not null default now()
);

create index transactions_user_posted_idx on public.transactions (user_id, posted_on desc);
create index transactions_account_idx on public.transactions (account_id);
create index transactions_category_idx on public.transactions (category_id);

alter table public.transactions enable row level security;

-- A row must belong to the signed-in user AND only reference that user's own
-- account and a default-or-own category, so data cannot be linked across users.
create policy "Users read their own transactions"
  on public.transactions for select to authenticated
  using (user_id = auth.uid());

create policy "Users add their own transactions"
  on public.transactions for insert to authenticated
  with check (
    user_id = auth.uid()
    and exists (select 1 from public.accounts a where a.id = account_id and a.user_id = auth.uid())
    and (category_id is null or exists (
      select 1 from public.categories c
      where c.id = category_id and (c.user_id is null or c.user_id = auth.uid())
    ))
  );

create policy "Users update their own transactions"
  on public.transactions for update to authenticated
  using (user_id = auth.uid())
  with check (
    user_id = auth.uid()
    and exists (select 1 from public.accounts a where a.id = account_id and a.user_id = auth.uid())
    and (category_id is null or exists (
      select 1 from public.categories c
      where c.id = category_id and (c.user_id is null or c.user_id = auth.uid())
    ))
  );

create policy "Users delete their own transactions"
  on public.transactions for delete to authenticated
  using (user_id = auth.uid());
