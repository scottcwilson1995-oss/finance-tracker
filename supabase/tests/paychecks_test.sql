-- paychecks: one per pay date. May link to the user's own income source and bank deposit.
insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000000a'),
  ('00000000-0000-0000-0000-00000000000b');
insert into public.accounts (id, user_id, source, name, type) values
  ('aaaaaaaa-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a', 'manual', 'A', 'cash'),
  ('bbbbbbbb-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000b', 'manual', 'B', 'cash');
insert into public.income_sources (id, user_id, name, kind, frequency) values
  ('aaaaaaaa-0000-0000-0000-0000000000e1', '00000000-0000-0000-0000-00000000000a', 'A employer', 'employer', 'monthly'),
  ('bbbbbbbb-0000-0000-0000-0000000000e1', '00000000-0000-0000-0000-00000000000b', 'B employer', 'employer', 'monthly');
insert into public.transactions (id, user_id, account_id, posted_on, amount, merchant) values
  ('aaaaaaaa-0000-0000-0000-0000000000d1', '00000000-0000-0000-0000-00000000000a', 'aaaaaaaa-0000-0000-0000-000000000001', '2026-11-05', -3000, 'A deposit'),
  ('bbbbbbbb-0000-0000-0000-0000000000d1', '00000000-0000-0000-0000-00000000000b', 'bbbbbbbb-0000-0000-0000-000000000001', '2026-11-05', -2500, 'B deposit');
insert into public.paychecks (user_id, income_source_id, pay_date, gross, net) values
  ('00000000-0000-0000-0000-00000000000b', 'bbbbbbbb-0000-0000-0000-0000000000e1', '2026-11-05', 4000, 2500);

set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';
do $$
declare n int;
begin
  select count(*) into n from public.paychecks;
  if n <> 0 then raise exception 'user A can see user B''s paycheck'; end if;

  insert into public.paychecks (income_source_id, pay_date, period_start, period_end, gross, net, deposit_transaction_id)
  values ('aaaaaaaa-0000-0000-0000-0000000000e1', '2026-11-05', '2026-10-01', '2026-10-31', 4200, 3000,
          'aaaaaaaa-0000-0000-0000-0000000000d1');

  begin
    insert into public.paychecks (income_source_id, pay_date, gross, net)
    values ('aaaaaaaa-0000-0000-0000-0000000000e1', '2026-11-05', 1, 1);
    raise exception 'two paychecks on the same pay date for one source accepted';
  exception when unique_violation then null;
  end;
  begin
    insert into public.paychecks (income_source_id, pay_date, gross, net)
    values ('bbbbbbbb-0000-0000-0000-0000000000e1', '2026-12-05', 1, 1);
    raise exception 'app linked a paycheck to user B''s income source';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.paychecks (pay_date, gross, net, deposit_transaction_id)
    values ('2026-12-05', 1, 1, 'bbbbbbbb-0000-0000-0000-0000000000d1');
    raise exception 'app linked a paycheck to user B''s deposit';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.paychecks (pay_date, gross, net) values ('2026-12-05', -1, 1);
    raise exception 'negative gross accepted';
  exception when check_violation then null;
  end;

  update public.paychecks set net = 3100 where pay_date = '2026-11-05' and income_source_id = 'aaaaaaaa-0000-0000-0000-0000000000e1';
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'app cannot edit its own paycheck'; end if;
  update public.paychecks set net = 0 where income_source_id = 'bbbbbbbb-0000-0000-0000-0000000000e1';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'app edited user B''s paycheck'; end if;
end $$;
