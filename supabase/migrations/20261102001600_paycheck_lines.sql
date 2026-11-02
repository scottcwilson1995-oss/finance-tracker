-- paycheck_lines: each line item of a paycheck, typed, with which tax wages it reduces
-- (federal / state / FICA) and this-period and year-to-date amounts. Employer-paid lines
-- (match, benefits) have payer = 'employer' and are not part of take-home.
create table public.paycheck_lines (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade default auth.uid(),
  paycheck_id uuid not null references public.paychecks (id) on delete cascade,
  line_type text not null check (line_type in (
    'earning', 'non_taxable_earning', 'tax', 'insurance', 'retirement', 'hsa', 'employer_benefit', 'other')),
  label text not null,
  payer text not null default 'employee' check (payer in ('employee', 'employer')),
  tax_treatment text not null default 'not_applicable' check (tax_treatment in ('pre_tax', 'post_tax', 'not_applicable')),
  reduces_federal boolean not null default false,
  reduces_state boolean not null default false,
  reduces_fica boolean not null default false,
  account_id uuid references public.accounts (id) on delete set null, -- where a contribution goes
  wages_this_period numeric(14, 2), -- taxable wages for this tax line
  this_period numeric(14, 2) not null,
  ytd numeric(14, 2),
  created_at timestamptz not null default now()
);

create index paycheck_lines_paycheck_idx on public.paycheck_lines (paycheck_id);
create index paycheck_lines_user_idx on public.paycheck_lines (user_id);

alter table public.paycheck_lines enable row level security;

create policy "Users read their own paycheck lines"
  on public.paycheck_lines for select to authenticated using (user_id = auth.uid());

create policy "Users add lines to their own paychecks"
  on public.paycheck_lines for insert to authenticated
  with check (
    user_id = auth.uid()
    and exists (select 1 from public.paychecks p where p.id = paycheck_id and p.user_id = auth.uid())
    and (account_id is null or private.owns_account(account_id))
  );

create policy "Users update lines of their own paychecks"
  on public.paycheck_lines for update to authenticated
  using (user_id = auth.uid())
  with check (
    user_id = auth.uid()
    and exists (select 1 from public.paychecks p where p.id = paycheck_id and p.user_id = auth.uid())
    and (account_id is null or private.owns_account(account_id))
  );

create policy "Users delete their own paycheck lines"
  on public.paycheck_lines for delete to authenticated using (user_id = auth.uid());
