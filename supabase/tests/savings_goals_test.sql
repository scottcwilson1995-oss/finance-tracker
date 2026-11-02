-- savings_goals: name, target amount and date; optionally linked to one of the user's accounts.
insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000000a'),
  ('00000000-0000-0000-0000-00000000000b');
insert into public.accounts (id, user_id, source, name, type) values
  ('aaaaaaaa-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a', 'manual', 'A savings', 'cash'),
  ('bbbbbbbb-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000b', 'manual', 'B savings', 'cash');
insert into public.savings_goals (user_id, name, target_amount) values
  ('00000000-0000-0000-0000-00000000000b', 'B trip', 2000);

set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';
do $$
declare n int;
begin
  select count(*) into n from public.savings_goals;
  if n <> 0 then raise exception 'user A can see user B''s goal'; end if;

  insert into public.savings_goals (name, target_amount, target_date, linked_account_id)
  values ('Trip', 3000, '2027-06-01', 'aaaaaaaa-0000-0000-0000-000000000001');
  update public.savings_goals set target_amount = 3500 where name = 'Trip';
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'app cannot edit its own goal'; end if;

  begin
    insert into public.savings_goals (name, target_amount, linked_account_id)
    values ('x', 10, 'bbbbbbbb-0000-0000-0000-000000000001');
    raise exception 'app linked a goal to user B''s account';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.savings_goals (name, target_amount) values ('x', 0);
    raise exception 'zero target accepted';
  exception when check_violation then null;
  end;
  begin
    insert into public.savings_goals (user_id, name, target_amount) values ('00000000-0000-0000-0000-00000000000b', 'planted', 5);
    raise exception 'app created a goal for user B';
  exception when insufficient_privilege then null;
  end;

  delete from public.savings_goals where name = 'B trip';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'app deleted user B''s goal'; end if;
end $$;
