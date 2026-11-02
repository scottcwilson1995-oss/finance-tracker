-- income_sources: employer, side income, rental, interest etc. Fully user-managed.
insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000000a'),
  ('00000000-0000-0000-0000-00000000000b');
insert into public.income_sources (user_id, name, kind, expected_amount, frequency) values
  ('00000000-0000-0000-0000-00000000000b', 'B employer', 'employer', 3000, 'monthly');

set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';
do $$
declare n int;
begin
  select count(*) into n from public.income_sources;
  if n <> 0 then raise exception 'user A can see user B''s income source'; end if;

  insert into public.income_sources (name, kind, expected_amount, frequency, next_payday)
  values ('My employer', 'employer', 4000, 'monthly', '2026-12-05');
  update public.income_sources set expected_amount = 4100 where name = 'My employer';
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'app cannot edit its own income source'; end if;

  update public.income_sources set name = 'hijacked' where name = 'B employer';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'app edited user B''s income source'; end if;
  delete from public.income_sources where name = 'B employer';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'app deleted user B''s income source'; end if;

  begin
    insert into public.income_sources (user_id, name, kind, frequency)
    values ('00000000-0000-0000-0000-00000000000b', 'planted', 'other', 'monthly');
    raise exception 'app created an income source for user B';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.income_sources (name, kind, frequency) values ('x', 'lottery', 'monthly');
    raise exception 'bad kind accepted';
  exception when check_violation then null;
  end;

  delete from public.income_sources where name = 'My employer';
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'app cannot delete its own income source'; end if;
end $$;
