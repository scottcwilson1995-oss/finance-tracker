-- plaid_items: one row per bank login. Written ONLY by server-side functions
-- (service_role). The app can read its own rows and nothing else.
insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000000a'),
  ('00000000-0000-0000-0000-00000000000b');

-- No column may hold a Plaid secret; the token lives in Vault, referenced by id.
do $$
declare bad text;
begin
  select string_agg(column_name, ', ') into bad
  from information_schema.columns
  where table_schema = 'public' and table_name = 'plaid_items'
    and column_name ~* '(access_token|secret|public_token)'
    and column_name <> 'vault_secret_id'; -- just an id pointing into Vault, not a secret
  if bad is not null then raise exception 'plaid_items has secret-looking columns: %', bad; end if;
end $$;

-- The server (service_role) creates rows for users.
set role service_role;
insert into public.plaid_items (user_id, plaid_item_id, institution_name, vault_secret_id) values
  ('00000000-0000-0000-0000-00000000000a', 'item_a', 'Bank A', gen_random_uuid()),
  ('00000000-0000-0000-0000-00000000000b', 'item_b', 'Bank B', gen_random_uuid());
reset role;

set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';

do $$
declare n int;
begin
  select count(*) into n from public.plaid_items;
  if n <> 1 then raise exception 'user A should see exactly 1 item, saw %', n; end if;

  -- The app cannot write at all, even to its own rows
  begin
    insert into public.plaid_items (user_id, plaid_item_id, institution_name, vault_secret_id)
    values ('00000000-0000-0000-0000-00000000000a', 'item_x', 'Bank X', gen_random_uuid());
    raise exception 'user A inserted a plaid_item from the app';
  exception when insufficient_privilege then null;
  end;

  begin
    update public.plaid_items set institution_name = 'hijacked';
    raise exception 'user A updated a plaid_item from the app';
  exception when insufficient_privilege then null;
  end;

  begin
    delete from public.plaid_items;
    raise exception 'user A deleted a plaid_item from the app';
  exception when insufficient_privilege then null;
  end;
end $$;

-- Signed-out users get nothing
reset role;
set role anon;
reset request.jwt.claim.sub;
do $$
declare n int;
begin
  begin
    select count(*) into n from public.plaid_items;
    if n <> 0 then raise exception 'anon can see plaid_items'; end if;
  exception when insufficient_privilege then null;
  end;
end $$;
