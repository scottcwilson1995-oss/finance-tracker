-- Minimal stand-ins for what Supabase provides, so migrations and RLS policies
-- can be tested on plain Postgres. Test-only: never applied to the hosted project.
create role anon nologin;
create role authenticated nologin;
create role service_role nologin bypassrls;

create schema auth;
create table auth.users (id uuid primary key default gen_random_uuid());

-- Supabase's auth.uid() reads the JWT claims PostgREST puts in this setting.
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;

-- Real Supabase lets the API roles use the auth schema and call auth.uid().
grant usage on schema auth to anon, authenticated, service_role;
grant execute on function auth.uid() to anon, authenticated, service_role;

grant usage on schema public to anon, authenticated, service_role;
alter default privileges in schema public grant all on tables to authenticated, service_role;
alter default privileges in schema public grant all on sequences to authenticated, service_role;
