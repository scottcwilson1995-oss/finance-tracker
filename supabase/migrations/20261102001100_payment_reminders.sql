-- payment_reminders: notify N days before an account's due date (e.g. 5 and 1).
-- Allowed on any of the user's own accounts, including Plaid-linked ones.
create table public.payment_reminders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade default auth.uid(),
  account_id uuid not null references public.accounts (id) on delete cascade,
  days_before integer not null check (days_before between 0 and 60),
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  unique (account_id, days_before)
);

create index payment_reminders_user_idx on public.payment_reminders (user_id);

alter table public.payment_reminders enable row level security;

create policy "Users read their own reminders"
  on public.payment_reminders for select to authenticated
  using (user_id = auth.uid());

create policy "Users add reminders to their own accounts"
  on public.payment_reminders for insert to authenticated
  with check (user_id = auth.uid() and private.owns_account(account_id));

create policy "Users update their own reminders"
  on public.payment_reminders for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid() and private.owns_account(account_id));

create policy "Users delete their own reminders"
  on public.payment_reminders for delete to authenticated
  using (user_id = auth.uid());
