create extension if not exists pgcrypto;

create table if not exists public.public_holidays (
  holiday_date date primary key,
  name text not null,
  country_code text not null default 'PL'
);

create table if not exists public.leave_year_balances (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  year integer not null check (year between 2000 and 2100),
  vacation_base_days integer not null default 28 check (vacation_base_days >= 0),
  vacation_carryover_days integer not null default 0 check (vacation_carryover_days >= 0),
  additional_base_days integer not null default 0 check (additional_base_days >= 0),
  additional_carryover_days integer not null default 0 check (additional_carryover_days >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, year)
);

create table if not exists public.leave_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_by uuid not null references public.profiles(id) on delete restrict,
  leave_type text not null check (leave_type in ('vacation', 'additional')),
  status text not null check (status in ('planned', 'used', 'cancelled')),
  start_date date not null,
  end_date date not null,
  working_days integer not null default 0 check (working_days >= 0),
  title text null,
  notes text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint leave_requests_date_order check (end_date >= start_date)
);

create index if not exists idx_leave_requests_user_id on public.leave_requests(user_id);
create index if not exists idx_leave_requests_status on public.leave_requests(status);
create index if not exists idx_leave_requests_start_date on public.leave_requests(start_date);
create index if not exists idx_leave_requests_user_status_date
  on public.leave_requests(user_id, status, start_date);

create or replace function public.count_business_days(
  p_start_date date,
  p_end_date date
)
returns integer
language sql
stable
as $$
  with days as (
    select gs::date as day_value
    from generate_series(p_start_date, p_end_date, interval '1 day') as gs
  )
  select count(*)::integer
  from days d
  where extract(isodow from d.day_value) between 1 and 5
    and not exists (
      select 1
      from public.public_holidays h
      where h.holiday_date = d.day_value
        and h.country_code = 'PL'
    );
$$;

create or replace function public.set_leave_request_working_days()
returns trigger
language plpgsql
as $$
begin
  new.working_days := public.count_business_days(new.start_date, new.end_date);
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_leave_requests_set_working_days on public.leave_requests;
create trigger trg_leave_requests_set_working_days
before insert or update of start_date, end_date
on public.leave_requests
for each row
execute function public.set_leave_request_working_days();

create or replace function public.set_updated_at_leave_year_balances()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_leave_year_balances_updated_at on public.leave_year_balances;
create trigger trg_leave_year_balances_updated_at
before update on public.leave_year_balances
for each row
execute function public.set_updated_at_leave_year_balances();

alter table public.public_holidays enable row level security;
alter table public.leave_year_balances enable row level security;
alter table public.leave_requests enable row level security;

drop policy if exists public_holidays_select_authenticated on public.public_holidays;
create policy public_holidays_select_authenticated
on public.public_holidays
for select
to authenticated
using (true);

drop policy if exists leave_year_balances_select_authenticated on public.leave_year_balances;
create policy leave_year_balances_select_authenticated
on public.leave_year_balances
for select
to authenticated
using (true);

drop policy if exists leave_year_balances_insert_own on public.leave_year_balances;
create policy leave_year_balances_insert_own
on public.leave_year_balances
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists leave_year_balances_update_own on public.leave_year_balances;
create policy leave_year_balances_update_own
on public.leave_year_balances
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists leave_requests_select_authenticated on public.leave_requests;
create policy leave_requests_select_authenticated
on public.leave_requests
for select
to authenticated
using (true);

drop policy if exists leave_requests_insert_own on public.leave_requests;
create policy leave_requests_insert_own
on public.leave_requests
for insert
to authenticated
with check (user_id = auth.uid() and created_by = auth.uid());

drop policy if exists leave_requests_update_own on public.leave_requests;
create policy leave_requests_update_own
on public.leave_requests
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists leave_requests_delete_own on public.leave_requests;
create policy leave_requests_delete_own
on public.leave_requests
for delete
to authenticated
using (user_id = auth.uid());