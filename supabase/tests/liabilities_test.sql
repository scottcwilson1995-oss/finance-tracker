-- liabilities: credit card / mortgage / loan details for an account (1:1).
-- The app can read its own, and write only for its own MANUAL accounts.
-- Plaid-linked accounts' liabilities are written by the server.
insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000000a'),
  ('00000000-0000-0000-0000-00000000000b');

set role service_role;
insert into public.plaid_items (id, user_id, plaid_item_id, vault_secret_id) values
  ('cccccccc-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a', 'item_a', gen_random_uuid());
insert into public.accounts (id, user_id, source, name, type, plaid_item_id, plaid_account_id) values
  ('aaaaaaaa-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a', 'plaid', 'A card', 'credit',
   'cccccccc-0000-0000-0000-000000000001', 'pa1');
insert into public.accounts (id, user_id, source, name, type) values
  ('aaaaaaaa-0000-0000-0000-000000000002', '00000000-0000-0000-0000-00000000000a', 'manual', 'Friend loan', 'loan'),
  ('bbbbbbbb-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000b', 'manual', 'B loan', 'loan');
-- The server writes the Plaid card's liability
insert into public.liabilities (account_id, user_id, kind, statement_balance, minimum_payment, next_due_date) values
  ('aaaaaaaa-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a', 'credit_card', 250.00, 35.00, '2026-11-20');
insert into public.liabilities (account_id, user_id, kind, original_amount, interest_rate, direction) values
  ('bbbbbbbb-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000b', 'personal_loan', 1000, 0, 'owe');
reset role;

set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';
do $$
declare n int;
begin
  select count(*) into n from public.liabilities;
  if n <> 1 then raise exception 'user A should see 1 liability, saw %', n; end if;

  -- Manual personal loan, money owed TO me, 0% rate, entered from the app
  insert into public.liabilities (account_id, kind, other_party, original_amount, interest_rate,
                                  payment_amount, payment_frequency, start_date, direction)
  values ('aaaaaaaa-0000-0000-0000-000000000002', 'personal_loan', 'Sam', 500, 0, 50, 'monthly', '2026-10-01', 'owed_to_me');
  update public.liabilities set payment_amount = 75 where account_id = 'aaaaaaaa-0000-0000-0000-000000000002';
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'app cannot edit its own manual liability'; end if;

  -- Cannot write the Plaid-linked card's liability
  update public.liabilities set minimum_payment = 0 where account_id = 'aaaaaaaa-0000-0000-0000-000000000001';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'app edited a plaid liability'; end if;
  delete from public.liabilities where account_id = 'aaaaaaaa-0000-0000-0000-000000000001';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'app deleted a plaid liability'; end if;

  -- Cannot attach a liability to someone else's account
  begin
    update public.liabilities set payment_amount = 1 where account_id = 'bbbbbbbb-0000-0000-0000-000000000001';
    get diagnostics n = row_count;
    if n <> 0 then raise exception 'app edited user B''s liability'; end if;
    insert into public.liabilities (account_id, kind) values ('bbbbbbbb-0000-0000-0000-000000000001', 'personal_loan');
    raise exception 'app added a liability to user B''s account';
  exception when insufficient_privilege then null;
  end;

  -- Bad values are rejected
  begin
    insert into public.liabilities (account_id, kind, direction) values ('aaaaaaaa-0000-0000-0000-000000000002', 'personal_loan', 'sideways');
    raise exception 'bad direction accepted';
  exception when check_violation or unique_violation then null;
  end;
end $$;
