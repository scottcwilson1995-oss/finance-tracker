-- payment_reminders: notify N days before an account's due date. Any of the user's own accounts.
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
  ('bbbbbbbb-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000b', 'manual', 'B loan', 'loan');
insert into public.payment_reminders (user_id, account_id, days_before) values
  ('00000000-0000-0000-0000-00000000000b', 'bbbbbbbb-0000-0000-0000-000000000001', 3);
reset role;

set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';
do $$
declare n int;
begin
  select count(*) into n from public.payment_reminders;
  if n <> 0 then raise exception 'user A can see user B''s reminder'; end if;

  -- Reminders 5 and 1 days before, on a Plaid-linked card (allowed)
  insert into public.payment_reminders (account_id, days_before) values ('aaaaaaaa-0000-0000-0000-000000000001', 5);
  insert into public.payment_reminders (account_id, days_before) values ('aaaaaaaa-0000-0000-0000-000000000001', 1);
  update public.payment_reminders set enabled = false where days_before = 1;
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'app cannot disable its own reminder'; end if;

  begin
    insert into public.payment_reminders (account_id, days_before) values ('aaaaaaaa-0000-0000-0000-000000000001', 5);
    raise exception 'duplicate reminder accepted';
  exception when unique_violation then null;
  end;
  begin
    insert into public.payment_reminders (account_id, days_before) values ('aaaaaaaa-0000-0000-0000-000000000001', -1);
    raise exception 'negative days_before accepted';
  exception when check_violation then null;
  end;
  begin
    insert into public.payment_reminders (account_id, days_before) values ('bbbbbbbb-0000-0000-0000-000000000001', 2);
    raise exception 'app added a reminder to user B''s account';
  exception when insufficient_privilege then null;
  end;

  update public.payment_reminders set days_before = 9 where account_id = 'bbbbbbbb-0000-0000-0000-000000000001';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'app edited user B''s reminder'; end if;
  delete from public.payment_reminders where account_id = 'bbbbbbbb-0000-0000-0000-000000000001';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'app deleted user B''s reminder'; end if;
end $$;
