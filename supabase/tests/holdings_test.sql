-- holdings: investment positions in an account. App writes only for its manual accounts.
insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000000a'),
  ('00000000-0000-0000-0000-00000000000b');
set role service_role;
insert into public.plaid_items (id, user_id, plaid_item_id, vault_secret_id) values
  ('cccccccc-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a', 'item_a', gen_random_uuid());
insert into public.accounts (id, user_id, source, name, type, plaid_item_id, plaid_account_id) values
  ('aaaaaaaa-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a', 'plaid', 'A 401k', 'investment',
   'cccccccc-0000-0000-0000-000000000001', 'pa1');
insert into public.accounts (id, user_id, source, name, type) values
  ('aaaaaaaa-0000-0000-0000-000000000002', '00000000-0000-0000-0000-00000000000a', 'manual', 'A manual brokerage', 'investment'),
  ('bbbbbbbb-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000b', 'manual', 'B brokerage', 'investment');
insert into public.holdings (user_id, account_id, security_name, ticker, quantity, value, as_of) values
  ('00000000-0000-0000-0000-00000000000a', 'aaaaaaaa-0000-0000-0000-000000000001', 'Index fund', 'VTI', 10, 2500, '2026-11-02'),
  ('00000000-0000-0000-0000-00000000000b', 'bbbbbbbb-0000-0000-0000-000000000001', 'B stock', 'XYZ', 1, 99, '2026-11-02');
reset role;

set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';
do $$
declare n int;
begin
  select count(*) into n from public.holdings;
  if n <> 1 then raise exception 'user A should see 1 holding, saw %', n; end if;

  -- Own manual account: full control
  insert into public.holdings (account_id, security_name, quantity, value, as_of)
  values ('aaaaaaaa-0000-0000-0000-000000000002', 'Cash position', 1, 100, '2026-11-02');
  update public.holdings set value = 150 where security_name = 'Cash position';
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'app cannot edit its own manual holding'; end if;
  delete from public.holdings where security_name = 'Cash position';
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'app cannot delete its own manual holding'; end if;

  -- Plaid-linked account: read only
  begin
    insert into public.holdings (account_id, security_name, quantity, value, as_of)
    values ('aaaaaaaa-0000-0000-0000-000000000001', 'planted', 1, 1, '2026-11-02');
    raise exception 'app added a holding to a plaid account';
  exception when insufficient_privilege then null;
  end;
  update public.holdings set value = 0 where ticker = 'VTI';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'app edited a plaid holding'; end if;

  -- Someone else's account
  begin
    insert into public.holdings (account_id, security_name, quantity, value, as_of)
    values ('bbbbbbbb-0000-0000-0000-000000000001', 'planted', 1, 1, '2026-11-02');
    raise exception 'app added a holding to user B''s account';
  exception when insufficient_privilege then null;
  end;
end $$;
