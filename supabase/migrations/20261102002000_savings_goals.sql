-- savings_goals: e.g. a trip or large purchase, with a target amount and date.
-- May be linked to one of the user's accounts (progress then follows its balance).
create table public.savings_goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade default auth.uid(),
  name text not null,
  target_amount numeric(14, 2) not null check (target_amount > 0),
  target_date date,
  linked_account_id uuid references public.accounts (id) on delete set null,
  created_at timestamptz not null default now()
);

create index savings_goals_user_idx on public.savings_goals (user_id);

alter table public.savings_goals enable row level security;

create policy "Users read their own savings goals"
  on public.savings_goals for select to authenticated using (user_id = auth.uid());

create policy "Users add their own savings goals"
  on public.savings_goals for insert to authenticated
  with check (user_id = auth.uid() and (linked_account_id is null or private.owns_account(linked_account_id)));

create policy "Users update their own savings goals"
  on public.savings_goals for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid() and (linked_account_id is null or private.owns_account(linked_account_id)));

create policy "Users delete their own savings goals"
  on public.savings_goals for delete to authenticated using (user_id = auth.uid());
