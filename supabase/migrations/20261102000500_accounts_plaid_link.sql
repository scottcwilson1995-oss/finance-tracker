-- Link accounts to bank connections. Plaid-sourced accounts are owned by the
-- server (service_role); the app can only create and edit manual accounts.
alter table public.accounts
  add column plaid_item_id uuid references public.plaid_items (id) on delete set null,
  add column plaid_account_id text unique;

create index accounts_plaid_item_idx on public.accounts (plaid_item_id);

drop policy "Users manage their own accounts" on public.accounts;

create policy "Users read their own accounts"
  on public.accounts for select to authenticated
  using (user_id = auth.uid());

create policy "Users add their own manual accounts"
  on public.accounts for insert to authenticated
  with check (user_id = auth.uid() and source = 'manual' and plaid_item_id is null and plaid_account_id is null);

create policy "Users update their own manual accounts"
  on public.accounts for update to authenticated
  using (user_id = auth.uid() and source = 'manual')
  with check (user_id = auth.uid() and source = 'manual' and plaid_item_id is null and plaid_account_id is null);

create policy "Users delete their own manual accounts"
  on public.accounts for delete to authenticated
  using (user_id = auth.uid() and source = 'manual');
