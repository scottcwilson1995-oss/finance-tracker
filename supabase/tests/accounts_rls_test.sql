-- RLS: a signed-in user can only see and change their own accounts.
insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000000a'),
  ('00000000-0000-0000-0000-00000000000b');

-- Seed as the table owner (bypasses RLS), like a server-side sync would.
insert into public.accounts (user_id, source, name, type) values
  ('00000000-0000-0000-0000-00000000000a', 'manual', 'A checking', 'cash'),
  ('00000000-0000-0000-0000-00000000000b', 'manual', 'B checking', 'cash');

set role authenticated;

-- Signed in as user A
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';

do $$
declare n int;
begin
  select count(*) into n from public.accounts;
  if n <> 1 then raise exception 'user A should see exactly 1 account, saw %', n; end if;

  select count(*) into n from public.accounts where name = 'B checking';
  if n <> 0 then raise exception 'user A can see user B''s account'; end if;

  update public.accounts set name = 'hijacked' where name = 'B checking';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'user A updated user B''s account'; end if;

  delete from public.accounts where name = 'B checking';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'user A deleted user B''s account'; end if;
end $$;

-- A cannot create an account owned by B
do $$
begin
  begin
    insert into public.accounts (user_id, source, name, type)
    values ('00000000-0000-0000-0000-00000000000b', 'manual', 'planted', 'cash');
    raise exception 'user A inserted a row for user B';
  exception when insufficient_privilege then
    null; -- expected: RLS WITH CHECK rejects it
  end;
end $$;

-- A can create and read their own
insert into public.accounts (user_id, source, name, type)
values ('00000000-0000-0000-0000-00000000000a', 'manual', 'A savings', 'cash');

-- Anonymous (not signed in) sees nothing
reset role;
set role anon;
reset request.jwt.claim.sub;
do $$
declare n int;
begin
  begin
    select count(*) into n from public.accounts;
    if n <> 0 then raise exception 'anon can see accounts'; end if;
  exception when insufficient_privilege then
    null; -- also fine: anon has no access at all
  end;
end $$;
