-- recurring_streams: subscriptions, bills and recurring income.
-- Server writes plaid/detected streams. App: add manual ones; confirm/dismiss/relabel
-- any of its own; delete only manual ones (dismiss the rest).
insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000000a'),
  ('00000000-0000-0000-0000-00000000000b');
insert into public.accounts (id, user_id, source, name, type) values
  ('aaaaaaaa-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a', 'manual', 'A', 'cash'),
  ('bbbbbbbb-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000b', 'manual', 'B', 'cash');
set role service_role;
insert into public.recurring_streams (user_id, account_id, merchant, direction, frequency, average_amount, source, status) values
  ('00000000-0000-0000-0000-00000000000a', 'aaaaaaaa-0000-0000-0000-000000000001', 'Netflix', 'outflow', 'monthly', 15.49, 'plaid', 'pending'),
  ('00000000-0000-0000-0000-00000000000b', 'bbbbbbbb-0000-0000-0000-000000000001', 'B Gym', 'outflow', 'monthly', 40, 'plaid', 'pending');
reset role;

set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';
do $$
declare n int;
begin
  select count(*) into n from public.recurring_streams;
  if n <> 1 then raise exception 'user A should see 1 stream, saw %', n; end if;

  -- Confirm, relabel and dismiss a detected stream
  update public.recurring_streams set status = 'confirmed', expense_type = 'fixed' where merchant = 'Netflix';
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'app cannot confirm its own detected stream'; end if;
  update public.recurring_streams set status = 'dismissed' where merchant = 'Netflix';

  -- Cannot delete a detected stream
  delete from public.recurring_streams where merchant = 'Netflix';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'app deleted a detected stream'; end if;

  -- Add, edit and delete a manual one
  insert into public.recurring_streams (merchant, direction, frequency, average_amount, next_date, source, status)
  values ('Landlord', 'outflow', 'monthly', 1200, '2026-12-01', 'manual', 'confirmed');
  update public.recurring_streams set average_amount = 1250 where merchant = 'Landlord';
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'app cannot edit its manual stream'; end if;
  delete from public.recurring_streams where merchant = 'Landlord';
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'app cannot delete its manual stream'; end if;

  -- Cannot create server-owned kinds
  begin
    insert into public.recurring_streams (merchant, direction, frequency, average_amount, source)
    values ('Fake', 'outflow', 'monthly', 1, 'plaid');
    raise exception 'app created a plaid stream';
  exception when insufficient_privilege then null;
  end;

  -- Cannot touch user B's data or link to B's account
  begin
    insert into public.recurring_streams (account_id, merchant, direction, frequency, average_amount, source)
    values ('bbbbbbbb-0000-0000-0000-000000000001', 'planted', 'outflow', 'monthly', 1, 'manual');
    raise exception 'app linked a stream to user B''s account';
  exception when insufficient_privilege then null;
  end;
  update public.recurring_streams set status = 'dismissed' where merchant = 'B Gym';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'app edited user B''s stream'; end if;

  -- Bad values
  begin
    insert into public.recurring_streams (merchant, direction, frequency, average_amount, source)
    values ('x', 'sideways', 'monthly', 1, 'manual');
    raise exception 'bad direction accepted';
  exception when check_violation then null;
  end;
end $$;
