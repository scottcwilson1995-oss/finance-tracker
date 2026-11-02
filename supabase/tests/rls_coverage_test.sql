-- Guard: every table in public must have RLS enabled and at least one policy.
-- Catches a future migration that adds a table and forgets its protection.
do $$
declare t record;
begin
  for t in
    select c.relname, c.relrowsecurity,
           (select count(*) from pg_policy p where p.polrelid = c.oid) as policies
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind in ('r', 'p')
  loop
    if not t.relrowsecurity then
      raise exception 'public.% has no row level security', t.relname;
    end if;
    if t.policies = 0 then
      raise exception 'public.% has RLS enabled but no policies', t.relname;
    end if;
  end loop;
end $$;
