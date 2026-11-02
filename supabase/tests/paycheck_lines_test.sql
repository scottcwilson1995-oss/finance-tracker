-- paycheck_lines: typed line items of a paycheck. Must belong to the user's own paycheck;
-- a linked contribution account must be the user's own.
insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000000a'),
  ('00000000-0000-0000-0000-00000000000b');
insert into public.accounts (id, user_id, source, name, type) values
  ('aaaaaaaa-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a', 'manual', 'A 401k', 'investment'),
  ('bbbbbbbb-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000b', 'manual', 'B 401k', 'investment');
insert into public.paychecks (id, user_id, pay_date, gross, net) values
  ('aaaaaaaa-0000-0000-0000-0000000000f1', '00000000-0000-0000-0000-00000000000a', '2026-11-05', 4000, 3000),
  ('bbbbbbbb-0000-0000-0000-0000000000f1', '00000000-0000-0000-0000-00000000000b', '2026-11-05', 5000, 3500);
insert into public.paycheck_lines (user_id, paycheck_id, line_type, label, payer, tax_treatment, this_period, ytd) values
  ('00000000-0000-0000-0000-00000000000b', 'bbbbbbbb-0000-0000-0000-0000000000f1', 'tax', 'B federal', 'employee', 'post_tax', 500, 5000);

set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';
do $$
declare n int;
begin
  select count(*) into n from public.paycheck_lines;
  if n <> 0 then raise exception 'user A can see user B''s paycheck line'; end if;

  -- Traditional 401(k): pre-tax, reduces federal + state wages but NOT FICA wages
  insert into public.paycheck_lines (paycheck_id, line_type, label, payer, tax_treatment,
                                     reduces_federal, reduces_state, reduces_fica, account_id, this_period, ytd)
  values ('aaaaaaaa-0000-0000-0000-0000000000f1', 'retirement', 'Traditional 401(k)', 'employee', 'pre_tax',
          true, true, false, 'aaaaaaaa-0000-0000-0000-000000000001', 300, 3300);
  -- Employer match, shown separately from take-home
  insert into public.paycheck_lines (paycheck_id, line_type, label, payer, tax_treatment, this_period, ytd)
  values ('aaaaaaaa-0000-0000-0000-0000000000f1', 'employer_benefit', '401(k) match', 'employer', 'not_applicable', 120, 1320);

  select count(*) into n from public.paycheck_lines;
  if n <> 2 then raise exception 'user A should see 2 lines, saw %', n; end if;

  begin
    insert into public.paycheck_lines (paycheck_id, line_type, label, payer, tax_treatment, this_period)
    values ('bbbbbbbb-0000-0000-0000-0000000000f1', 'tax', 'planted', 'employee', 'post_tax', 1);
    raise exception 'app added a line to user B''s paycheck';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.paycheck_lines (paycheck_id, line_type, label, payer, tax_treatment, account_id, this_period)
    values ('aaaaaaaa-0000-0000-0000-0000000000f1', 'retirement', 'x', 'employee', 'pre_tax', 'bbbbbbbb-0000-0000-0000-000000000001', 1);
    raise exception 'app linked a line to user B''s account';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.paycheck_lines (paycheck_id, line_type, label, payer, tax_treatment, this_period)
    values ('aaaaaaaa-0000-0000-0000-0000000000f1', 'bonus-ish', 'x', 'employee', 'pre_tax', 1);
    raise exception 'bad line_type accepted';
  exception when check_violation then null;
  end;

  update public.paycheck_lines set this_period = 310 where label = 'Traditional 401(k)';
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'app cannot edit its own line'; end if;
  update public.paycheck_lines set this_period = 0 where label = 'B federal';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'app edited user B''s line'; end if;
end $$;

-- Deleting a paycheck removes its lines
reset role;
delete from public.paychecks where id = 'aaaaaaaa-0000-0000-0000-0000000000f1';
do $$
declare n int;
begin
  select count(*) into n from public.paycheck_lines where user_id = '00000000-0000-0000-0000-00000000000a';
  if n <> 0 then raise exception 'lines survived deleting their paycheck'; end if;
end $$;
