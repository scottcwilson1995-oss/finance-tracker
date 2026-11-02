-- paycheck_templates: reusable default breakdown so each payday is one tap, plus
-- withholding settings (filing status, extra withholding) for later year-end tax estimates.
-- `lines` is a JSON list copied into paycheck_lines when a paycheck is created from it.
create table public.paycheck_templates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade default auth.uid(),
  income_source_id uuid references public.income_sources (id) on delete set null,
  name text not null,
  filing_status text check (filing_status in ('single', 'married_joint', 'married_separate', 'head_of_household')),
  extra_withholding numeric(14, 2) not null default 0,
  lines jsonb not null default '[]'::jsonb check (jsonb_typeof(lines) = 'array'),
  created_at timestamptz not null default now()
);

create index paycheck_templates_user_idx on public.paycheck_templates (user_id);

alter table public.paycheck_templates enable row level security;

create policy "Users read their own paycheck templates"
  on public.paycheck_templates for select to authenticated using (user_id = auth.uid());

create policy "Users add their own paycheck templates"
  on public.paycheck_templates for insert to authenticated
  with check (
    user_id = auth.uid()
    and (income_source_id is null or exists (
      select 1 from public.income_sources s where s.id = income_source_id and s.user_id = auth.uid()))
  );

create policy "Users update their own paycheck templates"
  on public.paycheck_templates for update to authenticated
  using (user_id = auth.uid())
  with check (
    user_id = auth.uid()
    and (income_source_id is null or exists (
      select 1 from public.income_sources s where s.id = income_source_id and s.user_id = auth.uid()))
  );

create policy "Users delete their own paycheck templates"
  on public.paycheck_templates for delete to authenticated using (user_id = auth.uid());
