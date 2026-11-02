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

grant usage on schema public to anon, authenticated, service_role;
alter default privileges in schema public grant all on tables to authenticated, service_role;
alter default privileges in schema public grant all on sequences to authenticated, service_role;
