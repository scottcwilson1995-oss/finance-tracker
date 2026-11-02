-- user_settings.exclude_before hides older transactions from the app's view
-- (transactions_in_scope) without deleting them, so the date can be moved back.
insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000000a'),
  ('00000000-0000-0000-0000-00000000000b');
insert into public.accounts (id, user_id, source, name, type) values
  ('aaaaaaaa-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a', 'manual', 'A checking', 'cash'),
  ('bbbbbbbb-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000b', 'manual', 'B checking', 'cash');
insert into public.transactions (user_id, account_id, posted_on, amount, merchant) values
  ('00000000-0000-0000-0000-00000000000a', 'aaaaaaaa-0000-0000-0000-000000000001', '2026-01-15', 10, 'A old'),
  ('00000000-0000-0000-0000-00000000000a', 'aaaaaaaa-0000-0000-0000-000000000001', '2026-06-01', 20, 'A on cutoff'),
  ('00000000-0000-0000-0000-00000000000a', 'aaaaaaaa-0000-0000-0000-000000000001', '2026-09-01', 30, 'A new'),
  ('00000000-0000-0000-0000-00000000000b', 'bbbbbbbb-0000-0000-0000-000000000001', '2026-01-15', 40, 'B old');

set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';

do $$
declare n int;
begin
  -- No setting yet: everything is in scope
  select count(*) into n from public.transactions_in_scope;
  if n <> 3 then raise exception 'with no cutoff user A should see 3, saw %', n; end if;

  -- Set the cutoff: the date itself is included, earlier ones are hidden
  insert into public.user_settings (exclude_before) values ('2026-06-01');
  select count(*) into n from public.transactions_in_scope;
  if n <> 2 then raise exception 'with cutoff user A should see 2, saw %', n; end if;
  select count(*) into n from public.transactions_in_scope where merchant = 'A old';
  if n <> 0 then raise exception 'old transaction still in scope'; end if;
  select count(*) into n from public.transactions_in_scope where merchant = 'A on cutoff';
  if n <> 1 then raise exception 'transaction on the cutoff date should be included'; end if;

  -- Nothing was deleted: the raw table still has all three
  select count(*) into n from public.transactions;
  if n <> 3 then raise exception 'raw transactions should still be 3, saw %', n; end if;

  -- Moving the date back brings history back
  update public.user_settings set exclude_before = '2026-01-01';
  select count(*) into n from public.transactions_in_scope;
  if n <> 3 then raise exception 'moving the cutoff back should restore 3, saw %', n; end if;

  -- Clearing it also works
  update public.user_settings set exclude_before = null;
  select count(*) into n from public.transactions_in_scope;
  if n <> 3 then raise exception 'clearing the cutoff should restore 3, saw %', n; end if;
  update public.user_settings set exclude_before = '2026-06-01';

  -- Cannot write settings for someone else
  begin
    insert into public.user_settings (user_id, exclude_before)
    values ('00000000-0000-0000-0000-00000000000b', '2030-01-01');
    raise exception 'user A wrote user B''s settings';
  exception when insufficient_privilege then null;
  end;
end $$;

-- B is unaffected by A's cutoff and cannot see A's settings
reset role;
set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000b';
do $$
declare n int;
begin
  select count(*) into n from public.transactions_in_scope;
  if n <> 1 then raise exception 'user B should still see their 1 transaction, saw %', n; end if;
  select count(*) into n from public.user_settings;
  if n <> 0 then raise exception 'user B can see user A''s settings'; end if;
end $$;
