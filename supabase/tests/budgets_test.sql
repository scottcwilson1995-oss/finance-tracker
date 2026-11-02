-- budgets: one per user per month (dated the 1st). User-managed.
insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000000a'),
  ('00000000-0000-0000-0000-00000000000b');
insert into public.budgets (user_id, month) values ('00000000-0000-0000-0000-00000000000b', '2026-11-01');

set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';
do $$
declare n int;
begin
  select count(*) into n from public.budgets;
  if n <> 0 then raise exception 'user A can see user B''s budget'; end if;

  insert into public.budgets (month, rollover) values ('2026-11-01', true);
  begin
    insert into public.budgets (month) values ('2026-11-01');
    raise exception 'two budgets for the same month accepted';
  exception when unique_violation then null;
  end;
  begin
    insert into public.budgets (month) values ('2026-12-15');
    raise exception 'month not on the 1st accepted';
  exception when check_violation then null;
  end;
  begin
    insert into public.budgets (user_id, month) values ('00000000-0000-0000-0000-00000000000b', '2026-12-01');
    raise exception 'app created a budget for user B';
  exception when insufficient_privilege then null;
  end;

  update public.budgets set rollover = false where month = '2026-11-01';
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'app cannot edit its own budget'; end if;
  delete from public.budgets where user_id = '00000000-0000-0000-0000-00000000000b';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'app deleted user B''s budget'; end if;
end $$;
