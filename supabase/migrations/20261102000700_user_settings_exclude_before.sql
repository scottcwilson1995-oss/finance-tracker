-- Per-user settings. exclude_before hides transactions dated earlier than that
-- day from the app (via transactions_in_scope) WITHOUT deleting them, so moving
-- the date back brings the history back.
create table public.user_settings (
  user_id uuid primary key references auth.users (id) on delete cascade default auth.uid(),
  exclude_before date,
  updated_at timestamptz not null default now()
);

alter table public.user_settings enable row level security;

create policy "Users read their own settings"
  on public.user_settings for select to authenticated
  using (user_id = auth.uid());

create policy "Users add their own settings"
  on public.user_settings for insert to authenticated
  with check (user_id = auth.uid());

create policy "Users update their own settings"
  on public.user_settings for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "Users delete their own settings"
  on public.user_settings for delete to authenticated
  using (user_id = auth.uid());

-- The app reads transactions through this view. security_invoker makes it run
-- with the caller's permissions, so row level security on both tables still applies.
create view public.transactions_in_scope
  with (security_invoker = true) as
select t.*
from public.transactions t
left join public.user_settings s on s.user_id = t.user_id
where s.exclude_before is null or t.posted_on >= s.exclude_before;
