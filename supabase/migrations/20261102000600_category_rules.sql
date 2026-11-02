-- category_rules: e.g. "merchant contains STARBUCKS -> Coffee", applied to future transactions.
create table public.category_rules (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade default auth.uid(),
  match_text text not null check (length(trim(match_text)) > 0),
  category_id uuid not null references public.categories (id) on delete cascade,
  created_at timestamptz not null default now()
);

create index category_rules_user_idx on public.category_rules (user_id);

alter table public.category_rules enable row level security;

create policy "Users read their own rules"
  on public.category_rules for select to authenticated
  using (user_id = auth.uid());

create policy "Users add their own rules"
  on public.category_rules for insert to authenticated
  with check (
    user_id = auth.uid()
    and exists (select 1 from public.categories c where c.id = category_id and (c.user_id is null or c.user_id = auth.uid()))
  );

create policy "Users update their own rules"
  on public.category_rules for update to authenticated
  using (user_id = auth.uid())
  with check (
    user_id = auth.uid()
    and exists (select 1 from public.categories c where c.id = category_id and (c.user_id is null or c.user_id = auth.uid()))
  );

create policy "Users delete their own rules"
  on public.category_rules for delete to authenticated
  using (user_id = auth.uid());
