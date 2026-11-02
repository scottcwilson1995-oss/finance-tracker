-- budget_lines: monthly amount per category. Own budget; category must be a default or own.
insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000000a'),
  ('00000000-0000-0000-0000-00000000000b');
insert into public.categories (id, user_id, name) values
  ('bbbbbbbb-0000-0000-0000-0000000000c1', '00000000-0000-0000-0000-00000000000b', 'B private');
insert into public.budgets (id, user_id, month) values
  ('aaaaaaaa-0000-0000-0000-0000000000b1', '00000000-0000-0000-0000-00000000000a', '2026-11-01'),
  ('bbbbbbbb-0000-0000-0000-0000000000b1', '00000000-0000-0000-0000-00000000000b', '2026-11-01');
insert into public.budget_lines (user_id, budget_id, category_id, amount) values
  ('00000000-0000-0000-0000-00000000000b', 'bbbbbbbb-0000-0000-0000-0000000000b1', 'bbbbbbbb-0000-0000-0000-0000000000c1', 100);

set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';
do $$
declare n int; food uuid; mine uuid;
begin
  select count(*) into n from public.budget_lines;
  if n <> 0 then raise exception 'user A can see user B''s budget line'; end if;

  select id into food from public.categories where name = 'Food' and user_id is null;
  insert into public.budget_lines (budget_id, category_id, amount) values ('aaaaaaaa-0000-0000-0000-0000000000b1', food, 600);

  insert into public.categories (name) values ('A coffee') returning id into mine;
  insert into public.budget_lines (budget_id, category_id, amount) values ('aaaaaaaa-0000-0000-0000-0000000000b1', mine, 40);

  begin
    insert into public.budget_lines (budget_id, category_id, amount) values ('aaaaaaaa-0000-0000-0000-0000000000b1', food, 1);
    raise exception 'two lines for the same category in one budget accepted';
  exception when unique_violation then null;
  end;
  begin
    insert into public.budget_lines (budget_id, category_id, amount) values ('aaaaaaaa-0000-0000-0000-0000000000b1', mine, -5);
    raise exception 'negative amount accepted';
  exception when unique_violation or check_violation then null;
  end;
  begin
    insert into public.budget_lines (budget_id, category_id, amount)
    values ('bbbbbbbb-0000-0000-0000-0000000000b1', food, 1);
    raise exception 'app added a line to user B''s budget';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.budget_lines (budget_id, category_id, amount)
    values ('aaaaaaaa-0000-0000-0000-0000000000b1', 'bbbbbbbb-0000-0000-0000-0000000000c1', 1);
    raise exception 'app used user B''s private category';
  exception when insufficient_privilege then null;
  end;

  update public.budget_lines set amount = 650 where category_id = food;
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'app cannot edit its own line'; end if;
  update public.budget_lines set amount = 0 where budget_id = 'bbbbbbbb-0000-0000-0000-0000000000b1';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'app edited user B''s line'; end if;
end $$;
