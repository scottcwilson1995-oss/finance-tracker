-- Smoke test: the harness boots Postgres and the Supabase stand-ins work.
do $$
begin
  set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
  if auth.uid() is distinct from '00000000-0000-0000-0000-000000000001'::uuid then
    raise exception 'auth.uid() did not read the JWT claim';
  end if;
end $$;
