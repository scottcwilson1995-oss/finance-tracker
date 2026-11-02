-- paycheck_templates: reusable default breakdown + withholding settings. User-managed.
insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000000a'),
  ('00000000-0000-0000-0000-00000000000b');
insert into public.income_sources (id, user_id, name, kind, frequency) values
  ('aaaaaaaa-0000-0000-0000-0000000000e1', '00000000-0000-0000-0000-00000000000a', 'A employer', 'employer', 'monthly'),
  ('bbbbbbbb-0000-0000-0000-0000000000e1', '00000000-0000-0000-0000-00000000000b', 'B employer', 'employer', 'monthly');
insert into public.paycheck_templates (user_id, income_source_id, name) values
  ('00000000-0000-0000-0000-00000000000b', 'bbbbbbbb-0000-0000-0000-0000000000e1', 'B template');

set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';
do $$
declare n int;
begin
  select count(*) into n from public.paycheck_templates;
  if n <> 0 then raise exception 'user A can see user B''s template'; end if;

  insert into public.paycheck_templates (income_source_id, name, filing_status, extra_withholding, lines)
  values ('aaaaaaaa-0000-0000-0000-0000000000e1', 'Monthly', 'single', 0,
          '[{"label":"Medical","line_type":"insurance","amount":150}]');
  update public.paycheck_templates set extra_withholding = 25 where name = 'Monthly';
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'app cannot edit its own template'; end if;

  begin
    insert into public.paycheck_templates (income_source_id, name)
    values ('bbbbbbbb-0000-0000-0000-0000000000e1', 'planted');
    raise exception 'app linked a template to user B''s income source';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.paycheck_templates (name, lines) values ('bad', '{"not":"a list"}');
    raise exception 'non-list lines accepted';
  exception when check_violation then null;
  end;

  delete from public.paycheck_templates where name = 'B template';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'app deleted user B''s template'; end if;
end $$;
