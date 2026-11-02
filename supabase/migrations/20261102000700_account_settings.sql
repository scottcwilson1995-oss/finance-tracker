-- Per-account settings. exclude_before hides that account's transactions dated
-- earlier than the day from the app (via transactions_in_scope) WITHOUT deleting
-- them, so moving the date back brings the history back. The app may set this on
-- any of the user's accounts, including Plaid-linked ones (which are otherwise
-- server-owned), because it only changes what is shown.
create table public.account_settings (
  account_id uuid primary key references public.accounts (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade default auth.uid(),
  exclude_before date,
  updated_at timestamptz not null default now()
);

alter table public.account_settings enable row level security;

create policy "Users read their own account settings"
  on public.account_settings for select to authenticated
  using (user_id = auth.uid());

create policy "Users add settings for their own accounts"
  on public.account_settings for insert to authenticated
  with check (
    user_id = auth.uid()
    and exists (select 1 from public.accounts a where a.id = account_id and a.user_id = auth.uid())
  );

create policy "Users update settings for their own accounts"
  on public.account_settings for update to authenticated
  using (user_id = auth.uid())
  with check (
    user_id = auth.uid()
    and exists (select 1 from public.accounts a where a.id = account_id and a.user_id = auth.uid())
  );

create policy "Users delete their own account settings"
  on public.account_settings for delete to authenticated
  using (user_id = auth.uid());

-- The app reads transactions through this view. security_invoker makes it run
-- with the caller's permissions, so row level security on every table still applies.
create view public.transactions_in_scope
  with (security_invoker = true) as
select t.*
from public.transactions t
left join public.account_settings s on s.account_id = t.account_id
where s.exclude_before is null or t.posted_on >= s.exclude_before;
