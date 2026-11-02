-- transactions: per-user rows; cannot reference another user's account or category.
insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000000a'),
  ('00000000-0000-0000-0000-00000000000b');

insert into public.accounts (id, user_id, source, name, type) values
  ('aaaaaaaa-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a', 'manual', 'A checking', 'cash'),
  ('bbbbbbbb-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000b', 'manual', 'B checking', 'cash');
insert into public.categories (id, user_id, name) values
  ('bbbbbbbb-0000-0000-0000-0000000000c1', '00000000-0000-0000-0000-00000000000b', 'B private');
insert into public.transactions (user_id, account_id, posted_on, amount, merchant) values
  ('00000000-0000-0000-0000-00000000000a', 'aaaaaaaa-0000-0000-0000-000000000001', '2026-11-01', 12.50, 'A cafe'),
  ('00000000-0000-0000-0000-00000000000b', 'bbbbbbbb-0000-0000-0000-000000000001', '2026-11-01', 99.00, 'B shop');

set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';

do $$
declare n int; d uuid;
begin
  select count(*) into n from public.transactions;
  if n <> 1 then raise exception 'user A should see 1 transaction, saw %', n; end if;

  update public.transactions set merchant = 'hijacked' where merchant = 'B shop';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'user A updated user B''s transaction'; end if;

  delete from public.transactions where merchant = 'B shop';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'user A deleted user B''s transaction'; end if;

  -- Own account + a default category is fine, and category_source defaults to plaid
  select id into d from public.categories where name = 'Food' and user_id is null;
  insert into public.transactions (account_id, posted_on, amount, merchant, category_id, category_source)
  values ('aaaaaaaa-0000-0000-0000-000000000001', '2026-11-02', 5.00, 'A lunch', d, 'manual');

  -- Cannot post to someone else's account
  begin
    insert into public.transactions (account_id, posted_on, amount, merchant)
    values ('bbbbbbbb-0000-0000-0000-000000000001', '2026-11-02', 1.00, 'planted');
    raise exception 'user A added a transaction to user B''s account';
  exception when insufficient_privilege then null;
  end;

  -- Cannot use someone else's private category
  begin
    insert into public.transactions (account_id, posted_on, amount, merchant, category_id)
    values ('aaaaaaaa-0000-0000-0000-000000000001', '2026-11-02', 1.00, 'planted',
            'bbbbbbbb-0000-0000-0000-0000000000c1');
    raise exception 'user A used user B''s private category';
  exception when insufficient_privilege then null;
  end;

  -- Invalid category_source is rejected
  begin
    insert into public.transactions (account_id, posted_on, amount, merchant, category_source)
    values ('aaaaaaaa-0000-0000-0000-000000000001', '2026-11-02', 1.00, 'x', 'magic');
    raise exception 'bad category_source accepted';
  exception when check_violation then null;
  end;
end $$;

-- Signed-out users get nothing
reset role;
set role anon;
reset request.jwt.claim.sub;
do $$
declare n int;
begin
  begin
    select count(*) into n from public.transactions;
    if n <> 0 then raise exception 'anon can see transactions'; end if;
  exception when insufficient_privilege then null;
  end;
end $$;
