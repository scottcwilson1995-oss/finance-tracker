-- goal_contributions: money put toward a goal. Must be for the user's own goal.
insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000000a'),
  ('00000000-0000-0000-0000-00000000000b');
insert into public.savings_goals (id, user_id, name, target_amount) values
  ('aaaaaaaa-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-00000000000a', 'A trip', 3000),
  ('bbbbbbbb-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-00000000000b', 'B trip', 2000);
insert into public.goal_contributions (user_id, goal_id, amount, contributed_on) values
  ('00000000-0000-0000-0000-00000000000b', 'bbbbbbbb-0000-0000-0000-0000000000a1', 100, '2026-11-01');

set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';
do $$
declare n int;
begin
  select count(*) into n from public.goal_contributions;
  if n <> 0 then raise exception 'user A can see user B''s contribution'; end if;

  insert into public.goal_contributions (goal_id, amount, contributed_on, note)
  values ('aaaaaaaa-0000-0000-0000-0000000000a1', 200, '2026-11-02', 'bonus');
  -- a withdrawal is a negative contribution
  insert into public.goal_contributions (goal_id, amount, contributed_on)
  values ('aaaaaaaa-0000-0000-0000-0000000000a1', -50, '2026-11-03');
  update public.goal_contributions set amount = 250 where note = 'bonus';
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'app cannot edit its own contribution'; end if;

  begin
    insert into public.goal_contributions (goal_id, amount, contributed_on)
    values ('aaaaaaaa-0000-0000-0000-0000000000a1', 0, '2026-11-03');
    raise exception 'zero contribution accepted';
  exception when check_violation then null;
  end;
  begin
    insert into public.goal_contributions (goal_id, amount, contributed_on)
    values ('bbbbbbbb-0000-0000-0000-0000000000a1', 10, '2026-11-03');
    raise exception 'app contributed to user B''s goal';
  exception when insufficient_privilege then null;
  end;

  update public.goal_contributions set amount = 1 where goal_id = 'bbbbbbbb-0000-0000-0000-0000000000a1';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'app edited user B''s contribution'; end if;
  delete from public.goal_contributions where goal_id = 'bbbbbbbb-0000-0000-0000-0000000000a1';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'app deleted user B''s contribution'; end if;
end $$;
