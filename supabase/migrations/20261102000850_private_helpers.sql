-- Helpers for RLS policies. They live in a private schema so the API does not expose them.
-- Both run with the caller's rights (security invoker), so accounts RLS still applies.
create schema private;
grant usage on schema private to authenticated, service_role;

create function private.owns_account(p_account_id uuid) returns boolean
language sql stable security invoker as $$
  select exists (select 1 from public.accounts a where a.id = p_account_id and a.user_id = auth.uid())
$$;

-- Plaid-linked accounts are server-owned; the app may only write data for manual ones.
create function private.owns_manual_account(p_account_id uuid) returns boolean
language sql stable security invoker as $$
  select exists (
    select 1 from public.accounts a
    where a.id = p_account_id and a.user_id = auth.uid() and a.source = 'manual'
  )
$$;

grant execute on function private.owns_account(uuid), private.owns_manual_account(uuid) to authenticated, service_role;
