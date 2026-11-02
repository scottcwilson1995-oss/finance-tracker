-- loan_payments: payments logged against a MANUAL loan account. Own accounts only.
insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000000a'),
  ('00000000-0000-0000-0000-00000000000b');
set role service_role;
insert into public.plaid_items (id, user_id, plaid_item_id, vault_secret_id) values
  ('cccccccc-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a', 'item_a', gen_random_uuid());
insert into public.accounts (id, user_id, source, name, type, plaid_item_id, plaid_account_id) values
  ('aaaaaaaa-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a', 'plaid', 'A bank loan', 'loan',
   'cccccccc-0000-0000-0000-000000000001', 'pa1');
insert into public.accounts (id, user_id, source, name, type) values
  ('aaaaaaaa-0000-0000-0000-000000000002', '00000000-0000-0000-0000-00000000000a', 'manual', 'Sam loan', 'loan'),
  ('bbbbbbbb-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000b', 'manual', 'B loan', 'loan');
insert into public.loan_payments (user_id, account_id, paid_on, amount) values
  ('00000000-0000-0000-0000-00000000000b', 'bbbbbbbb-0000-0000-0000-000000000001', '2026-10-01', 100);
reset role;

set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';
do $$
declare n int;
begin
  select count(*) into n from public.loan_payments;
  if n <> 0 then raise exception 'user A can see user B''s payment'; end if;

  insert into public.loan_payments (account_id, paid_on, amount, note)
  values ('aaaaaaaa-0000-0000-0000-000000000002', '2026-11-01', 50, 'November');
  update public.loan_payments set amount = 55 where note = 'November';
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'app cannot edit its own payment'; end if;
  delete from public.loan_payments where note = 'November';
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'app cannot delete its own payment'; end if;

  begin
    insert into public.loan_payments (account_id, paid_on, amount)
    values ('aaaaaaaa-0000-0000-0000-000000000002', '2026-11-01', 0);
    raise exception 'zero payment accepted';
  exception when check_violation then null;
  end;
  begin
    insert into public.loan_payments (account_id, paid_on, amount)
    values ('aaaaaaaa-0000-0000-0000-000000000001', '2026-11-01', 50);
    raise exception 'app logged a payment on a plaid account';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.loan_payments (account_id, paid_on, amount)
    values ('bbbbbbbb-0000-0000-0000-000000000001', '2026-11-01', 50);
    raise exception 'app logged a payment on user B''s account';
  exception when insufficient_privilege then null;
  end;
end $$;
