-- budget_lines: planned monthly amount per category.
create table public.budget_lines (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade default auth.uid(),
  budget_id uuid not null references public.budgets (id) on delete cascade,
  category_id uuid not null references public.categories (id) on delete cascade,
  amount numeric(14, 2) not null check (amount >= 0),
  created_at timestamptz not null default now(),
  unique (budget_id, category_id)
);

create index budget_lines_user_idx on public.budget_lines (user_id);

alter table public.budget_lines enable row level security;

create policy "Users read their own budget lines"
  on public.budget_lines for select to authenticated using (user_id = auth.uid());

create policy "Users add lines to their own budgets"
  on public.budget_lines for insert to authenticated
  with check (
    user_id = auth.uid()
    and exists (select 1 from public.budgets b where b.id = budget_id and b.user_id = auth.uid())
    and exists (select 1 from public.categories c where c.id = category_id and (c.user_id is null or c.user_id = auth.uid()))
  );

create policy "Users update lines of their own budgets"
  on public.budget_lines for update to authenticated
  using (user_id = auth.uid())
  with check (
    user_id = auth.uid()
    and exists (select 1 from public.budgets b where b.id = budget_id and b.user_id = auth.uid())
    and exists (select 1 from public.categories c where c.id = category_id and (c.user_id is null or c.user_id = auth.uid()))
  );

create policy "Users delete their own budget lines"
  on public.budget_lines for delete to authenticated using (user_id = auth.uid());
