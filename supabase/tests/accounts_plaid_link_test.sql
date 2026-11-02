-- Plaid-linked accounts are server-owned. From the app a user can only
-- create/edit MANUAL accounts, and never link one to a bank connection.
insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000000a'),
  ('00000000-0000-0000-0000-00000000000b');

set role service_role;
insert into public.plaid_items (id, user_id, plaid_item_id, institution_name, vault_secret_id) values
  ('cccccccc-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a', 'item_a', 'Bank A', gen_random_uuid());
insert into public.accounts (id, user_id, source, name, type, plaid_item_id, plaid_account_id) values
  ('aaaaaaaa-0000-0000-0000-0000000000f1', '00000000-0000-0000-0000-00000000000a', 'plaid', 'A bank checking', 'cash',
   'cccccccc-0000-0000-0000-000000000001', 'plaid_acct_1');
reset role;

set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';

do $$
declare n int;
begin
  -- The user can read their Plaid-linked account
  select count(*) into n from public.accounts where source = 'plaid';
  if n <> 1 then raise exception 'user A should see their plaid account'; end if;

  -- Cannot create a plaid-sourced account from the app
  begin
    insert into public.accounts (source, name, type) values ('plaid', 'fake', 'cash');
    raise exception 'app created a plaid account';
  exception when insufficient_privilege then null;
  end;

  -- Cannot link a manual account to a bank connection
  begin
    insert into public.accounts (source, name, type, plaid_item_id)
    values ('manual', 'sneaky', 'cash', 'cccccccc-0000-0000-0000-000000000001');
    raise exception 'app linked a manual account to a plaid item';
  exception when insufficient_privilege then null;
  end;

  -- Cannot edit or delete a plaid-sourced account from the app
  update public.accounts set name = 'renamed' where source = 'plaid';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'app edited a plaid account'; end if;

  delete from public.accounts where source = 'plaid';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'app deleted a plaid account'; end if;

  -- Manual accounts still work normally
  insert into public.accounts (source, name, type) values ('manual', 'Onity mortgage', 'loan');
  update public.accounts set name = 'Onity' where name = 'Onity mortgage';
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'app cannot edit its own manual account'; end if;
end $$;
