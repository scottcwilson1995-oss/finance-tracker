-- contribution_limits: IRS yearly limits. Shared reference data: any signed-in user can
-- read it; only the server can change it.
insert into auth.users (id) values ('00000000-0000-0000-0000-00000000000a');

-- Seeded with the 2026 self-only HSA limit from the plan
do $$
declare v numeric;
begin
  select limit_amount into v from public.contribution_limits where tax_year = 2026 and kind = 'hsa_self';
  if v is distinct from 4400 then raise exception '2026 self-only HSA limit should be seeded as 4400, got %', v; end if;
end $$;

-- The server can add limits
set role service_role;
insert into public.contribution_limits (tax_year, kind, limit_amount) values (2026, 'ira', 1);
do $$
begin
  begin
    insert into public.contribution_limits (tax_year, kind, limit_amount) values (2026, 'ira', 2);
    raise exception 'duplicate year/kind accepted';
  exception when unique_violation then null;
  end;
end $$;
reset role;

set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';
do $$
declare n int;
begin
  select count(*) into n from public.contribution_limits;
  if n < 2 then raise exception 'signed-in user cannot read the limits'; end if;

  begin
    insert into public.contribution_limits (tax_year, kind, limit_amount) values (2027, 'ira', 1);
    raise exception 'app inserted a limit';
  exception when insufficient_privilege then null;
  end;
  begin
    update public.contribution_limits set limit_amount = 999999;
    raise exception 'app changed a limit';
  exception when insufficient_privilege then null;
  end;
  begin
    delete from public.contribution_limits;
    raise exception 'app deleted a limit';
  exception when insufficient_privilege then null;
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
    select count(*) into n from public.contribution_limits;
    if n <> 0 then raise exception 'anon can read the limits'; end if;
  exception when insufficient_privilege then null;
  end;
end $$;
