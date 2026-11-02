-- account_settings.exclude_before hides older transactions of ONE account from the
-- app's view (transactions_in_scope) without deleting them, so the date can move back.
insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000000a'),
  ('00000000-0000-0000-0000-00000000000b');

-- A has a Plaid-linked account (server-owned) and a manual one; B has one manual account.
set role service_role;
insert into public.plaid_items (id, user_id, plaid_item_id, vault_secret_id) values
  ('cccccccc-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a', 'item_a', gen_random_uuid());
insert into public.accounts (id, user_id, source, name, type, plaid_item_id, plaid_account_id) values
  ('aaaaaaaa-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a', 'plaid', 'A bank', 'cash',
   'cccccccc-0000-0000-0000-000000000001', 'pa1');
insert into public.accounts (id, user_id, source, name, type) values
  ('aaaaaaaa-0000-0000-0000-000000000002', '00000000-0000-0000-0000-00000000000a', 'manual', 'A manual', 'cash'),
  ('bbbbbbbb-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000b', 'manual', 'B manual', 'cash');
insert into public.transactions (user_id, account_id, posted_on, amount, merchant) values
  ('00000000-0000-0000-0000-00000000000a', 'aaaaaaaa-0000-0000-0000-000000000001', '2026-01-15', 10, 'bank old'),
  ('00000000-0000-0000-0000-00000000000a', 'aaaaaaaa-0000-0000-0000-000000000001', '2026-06-01', 20, 'bank on cutoff'),
  ('00000000-0000-0000-0000-00000000000a', 'aaaaaaaa-0000-0000-0000-000000000001', '2026-09-01', 30, 'bank new'),
  ('00000000-0000-0000-0000-00000000000a', 'aaaaaaaa-0000-0000-0000-000000000002', '2026-01-15', 5,  'manual old'),
  ('00000000-0000-0000-0000-00000000000b', 'bbbbbbbb-0000-0000-0000-000000000001', '2026-01-15', 40, 'B old');
reset role;

set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';

do $$
declare n int;
begin
  select count(*) into n from public.transactions_in_scope;
  if n <> 4 then raise exception 'with no cutoffs user A should see 4, saw %', n; end if;

  -- Cutoff on the Plaid-linked account only (the app may set this even though the account is server-owned)
  insert into public.account_settings (account_id, exclude_before)
  values ('aaaaaaaa-0000-0000-0000-000000000001', '2026-06-01');

  select count(*) into n from public.transactions_in_scope;
  if n <> 3 then raise exception 'with one cutoff user A should see 3, saw %', n; end if;
  select count(*) into n from public.transactions_in_scope where merchant = 'bank old';
  if n <> 0 then raise exception 'old bank transaction still in scope'; end if;
  select count(*) into n from public.transactions_in_scope where merchant = 'bank on cutoff';
  if n <> 1 then raise exception 'transaction on the cutoff date should be included'; end if;
  select count(*) into n from public.transactions_in_scope where merchant = 'manual old';
  if n <> 1 then raise exception 'cutoff on one account hid another account''s transaction'; end if;

  -- Nothing was deleted
  select count(*) into n from public.transactions;
  if n <> 4 then raise exception 'raw transactions should still be 4, saw %', n; end if;

  -- Moving the date back, or clearing it, restores history
  update public.account_settings set exclude_before = '2026-01-01';
  select count(*) into n from public.transactions_in_scope;
  if n <> 4 then raise exception 'moving the cutoff back should restore 4, saw %', n; end if;
  update public.account_settings set exclude_before = null;
  select count(*) into n from public.transactions_in_scope;
  if n <> 4 then raise exception 'clearing the cutoff should restore 4, saw %', n; end if;
  update public.account_settings set exclude_before = '2026-06-01';

  -- Cannot set a cutoff on someone else's account
  begin
    insert into public.account_settings (account_id, exclude_before)
    values ('bbbbbbbb-0000-0000-0000-000000000001', '2030-01-01');
    raise exception 'user A set a cutoff on user B''s account';
  exception when insufficient_privilege then null;
  end;
end $$;

-- B is unaffected and cannot see A's settings
reset role;
set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000b';
do $$
declare n int;
begin
  select count(*) into n from public.transactions_in_scope;
  if n <> 1 then raise exception 'user B should still see their 1 transaction, saw %', n; end if;
  select count(*) into n from public.account_settings;
  if n <> 0 then raise exception 'user B can see user A''s account settings'; end if;
end $$;
