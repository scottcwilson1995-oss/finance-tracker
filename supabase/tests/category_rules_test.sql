-- category_rules: "merchant contains X -> category". Per-user; category must be
-- a default or the user's own.
insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000000a'),
  ('00000000-0000-0000-0000-00000000000b');
insert into public.categories (id, user_id, name) values
  ('bbbbbbbb-0000-0000-0000-0000000000c1', '00000000-0000-0000-0000-00000000000b', 'B private');
insert into public.category_rules (user_id, match_text, category_id)
select '00000000-0000-0000-0000-00000000000b', 'B RULE', 'bbbbbbbb-0000-0000-0000-0000000000c1';

set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';

do $$
declare n int; d uuid;
begin
  select count(*) into n from public.category_rules;
  if n <> 0 then raise exception 'user A can see user B''s rule'; end if;

  select id into d from public.categories where name = 'Food' and user_id is null;
  insert into public.category_rules (match_text, category_id) values ('STARBUCKS', d);

  select count(*) into n from public.category_rules;
  if n <> 1 then raise exception 'user A should see their own rule only'; end if;

  begin
    insert into public.category_rules (match_text, category_id)
    values ('PLANTED', 'bbbbbbbb-0000-0000-0000-0000000000c1');
    raise exception 'user A used user B''s private category in a rule';
  exception when insufficient_privilege then null;
  end;

  begin
    insert into public.category_rules (user_id, match_text, category_id)
    values ('00000000-0000-0000-0000-00000000000b', 'PLANTED', d);
    raise exception 'user A created a rule for user B';
  exception when insufficient_privilege then null;
  end;

  update public.category_rules set match_text = 'hijacked' where match_text = 'B RULE';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'user A updated user B''s rule'; end if;

  delete from public.category_rules where match_text = 'B RULE';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'user A deleted user B''s rule'; end if;
end $$;
