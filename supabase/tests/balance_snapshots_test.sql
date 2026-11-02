-- balance_snapshots: one balance per account per day, for net worth history.
-- Written only by the server (daily job / sync); the app can read its own.
insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000000a'),
  ('00000000-0000-0000-0000-00000000000b');
insert into public.accounts (id, user_id, source, name, type) values
  ('aaaaaaaa-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a', 'manual', 'A', 'cash'),
  ('bbbbbbbb-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000b', 'manual', 'B', 'cash');

set role service_role;
insert into public.balance_snapshots (user_id, account_id, snapshot_on, balance) values
  ('00000000-0000-0000-0000-00000000000a', 'aaaaaaaa-0000-0000-0000-000000000001', '2026-11-01', 100.00),
  ('00000000-0000-0000-0000-00000000000a', 'aaaaaaaa-0000-0000-0000-000000000001', '2026-11-02', 110.00),
  ('00000000-0000-0000-0000-00000000000b', 'bbbbbbbb-0000-0000-0000-000000000001', '2026-11-01', 999.00);

-- One snapshot per account per day
do $$
begin
  begin
    insert into public.balance_snapshots (user_id, account_id, snapshot_on, balance)
    values ('00000000-0000-0000-0000-00000000000a', 'aaaaaaaa-0000-0000-0000-000000000001', '2026-11-01', 1);
    raise exception 'duplicate snapshot for the same account and day accepted';
  exception when unique_violation then null;
  end;
end $$;
reset role;

set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';
do $$
declare n int;
begin
  select count(*) into n from public.balance_snapshots;
  if n <> 2 then raise exception 'user A should see 2 snapshots, saw %', n; end if;

  begin
    insert into public.balance_snapshots (account_id, snapshot_on, balance)
    values ('aaaaaaaa-0000-0000-0000-000000000001', '2026-11-03', 1);
    raise exception 'app inserted a snapshot';
  exception when insufficient_privilege then null;
  end;
  begin
    update public.balance_snapshots set balance = 0;
    raise exception 'app updated a snapshot';
  exception when insufficient_privilege then null;
  end;
  begin
    delete from public.balance_snapshots;
    raise exception 'app deleted a snapshot';
  exception when insufficient_privilege then null;
  end;
end $$;
