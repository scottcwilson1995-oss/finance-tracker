-- goal_contributions: money put toward a savings goal (a negative amount is a withdrawal).
create table public.goal_contributions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade default auth.uid(),
  goal_id uuid not null references public.savings_goals (id) on delete cascade,
  amount numeric(14, 2) not null check (amount <> 0),
  contributed_on date not null,
  note text,
  created_at timestamptz not null default now()
);

create index goal_contributions_goal_idx on public.goal_contributions (goal_id, contributed_on desc);
create index goal_contributions_user_idx on public.goal_contributions (user_id);

alter table public.goal_contributions enable row level security;

create policy "Users read their own goal contributions"
  on public.goal_contributions for select to authenticated using (user_id = auth.uid());

create policy "Users add contributions to their own goals"
  on public.goal_contributions for insert to authenticated
  with check (
    user_id = auth.uid()
    and exists (select 1 from public.savings_goals g where g.id = goal_id and g.user_id = auth.uid())
  );

create policy "Users update contributions to their own goals"
  on public.goal_contributions for update to authenticated
  using (user_id = auth.uid())
  with check (
    user_id = auth.uid()
    and exists (select 1 from public.savings_goals g where g.id = goal_id and g.user_id = auth.uid())
  );

create policy "Users delete their own goal contributions"
  on public.goal_contributions for delete to authenticated using (user_id = auth.uid());
