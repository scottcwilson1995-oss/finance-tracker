-- Categories: a shared default set (user_id null) plus each user's own.
insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000000a'),
  ('00000000-0000-0000-0000-00000000000b');

-- Exactly 5 general default categories are seeded.
do $$
declare n int;
begin
  select count(*) into n from public.categories where user_id is null;
  if n <> 5 then raise exception 'expected 5 default categories, found %', n; end if;
end $$;

set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';

do $$
declare n int;
begin
  -- Users can see the defaults
  select count(*) into n from public.categories where user_id is null;
  if n <> 5 then raise exception 'user A should see 5 defaults, saw %', n; end if;

  -- Users cannot change or delete defaults
  update public.categories set name = 'hijacked' where user_id is null;
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'user A updated a default category'; end if;

  delete from public.categories where user_id is null;
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'user A deleted a default category'; end if;

  -- Users cannot create a shared default
  begin
    insert into public.categories (user_id, name, expense_type) values (null, 'planted', 'variable');
    raise exception 'user A created a default category';
  exception when insufficient_privilege then null;
  end;

  -- Users cannot create a category owned by someone else
  begin
    insert into public.categories (user_id, name, expense_type)
    values ('00000000-0000-0000-0000-00000000000b', 'planted', 'variable');
    raise exception 'user A created a category for user B';
  exception when insufficient_privilege then null;
  end;
end $$;

-- A creates their own category (user_id defaults to the signed-in user)
insert into public.categories (name, expense_type) values ('A coffee', 'variable');

do $$
declare n int;
begin
  select count(*) into n from public.categories where name = 'A coffee';
  if n <> 1 then raise exception 'user A cannot see their own category'; end if;
end $$;

-- B cannot see A's category but still sees the defaults
reset role;
set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000b';
do $$
declare n int;
begin
  select count(*) into n from public.categories where name = 'A coffee';
  if n <> 0 then raise exception 'user B can see user A''s category'; end if;
  select count(*) into n from public.categories;
  if n <> 5 then raise exception 'user B should see only the 5 defaults, saw %', n; end if;
end $$;
