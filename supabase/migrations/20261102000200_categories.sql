-- Categories: a shared default set (user_id is null) plus each user's own.
create table public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete cascade default auth.uid(),
  name text not null,
  color text not null default '#6b7280',
  expense_type text not null default 'variable' check (expense_type in ('fixed', 'variable')),
  created_at timestamptz not null default now()
);

-- Names are unique per owner (the shared defaults count as one owner).
create unique index categories_owner_name_idx
  on public.categories ((coalesce(user_id, '00000000-0000-0000-0000-000000000000'::uuid)), lower(name));

alter table public.categories enable row level security;

create policy "Users read defaults and their own categories"
  on public.categories for select to authenticated
  using (user_id is null or user_id = auth.uid());

create policy "Users manage their own categories"
  on public.categories for insert to authenticated
  with check (user_id = auth.uid());

create policy "Users update their own categories"
  on public.categories for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "Users delete their own categories"
  on public.categories for delete to authenticated
  using (user_id = auth.uid());

-- Default categories (about five general groups; users add their own for detail).
-- A transaction with no category is shown as "Uncategorized".
insert into public.categories (user_id, name, color, expense_type) values
  (null, 'Housing & Bills', '#2563eb', 'fixed'),
  (null, 'Food', '#16a34a', 'variable'),
  (null, 'Transportation', '#d97706', 'variable'),
  (null, 'Lifestyle', '#9333ea', 'variable'),
  (null, 'Health & Personal', '#dc2626', 'variable');
