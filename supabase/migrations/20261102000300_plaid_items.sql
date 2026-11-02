-- plaid_items: one row per connected bank login.
-- Written only by server-side Edge Functions (service_role). The Plaid access
-- token itself lives in Supabase Vault; this table only holds a reference to it.
create table public.plaid_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  plaid_item_id text not null unique,
  institution_name text,
  vault_secret_id uuid not null,
  sync_cursor text,
  status text not null default 'good' check (status in ('good', 'needs_reauth', 'error')),
  created_at timestamptz not null default now()
);

create index plaid_items_user_id_idx on public.plaid_items (user_id);

alter table public.plaid_items enable row level security;

create policy "Users read their own bank connections"
  on public.plaid_items for select to authenticated
  using (user_id = auth.uid());

-- Defense in depth: even without a write policy, the app roles get no write privileges.
revoke insert, update, delete on public.plaid_items from authenticated, anon;
