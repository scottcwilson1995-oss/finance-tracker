-- contribution_limits: IRS yearly limits (401(k), HSA, IRA). Shared reference data:
-- signed-in users read it; only the server (service_role) changes it.
create table public.contribution_limits (
  id uuid primary key default gen_random_uuid(),
  tax_year integer not null,
  kind text not null check (kind in (
    '401k', '401k_catchup', 'hsa_self', 'hsa_family', 'hsa_catchup', 'ira', 'ira_catchup')),
  limit_amount numeric(14, 2) not null check (limit_amount >= 0),
  unique (tax_year, kind)
);

alter table public.contribution_limits enable row level security;

create policy "Signed-in users read contribution limits"
  on public.contribution_limits for select to authenticated using (true);

revoke insert, update, delete on public.contribution_limits from authenticated, anon;

-- Seeded from the plan (self-only HSA coverage). The other limits are added once
-- confirmed against the IRS announcement for the year.
insert into public.contribution_limits (tax_year, kind, limit_amount) values (2026, 'hsa_self', 4400);
