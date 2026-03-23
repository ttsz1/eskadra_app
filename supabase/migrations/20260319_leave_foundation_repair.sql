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
  vacation_days integer not null default 0 check (vacation_days >= 0),
  additional_days integer not null default 0 check (additional_days >= 0),
  source text not null default 'manual'
    check (source in ('manual', 'auto_base')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, year, source)
);

create table if not exists public.leave_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_by uuid not null references public.profiles(id) on delete restrict,
  leave_type text not null
    check (leave_type in ('vacation', 'additional')),
  status text not null
    check (status in ('planned', 'used', 'cancelled')),
  start_date date,
  end_date date,
  working_days integer not null default 0,
  title text null,
  notes text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.leave_requests
  add column if not exists user_id uuid references public.profiles(id) on delete cascade;

alter table public.leave_requests
  add column if not exists created_by uuid references public.profiles(id) on delete restrict;

alter table public.leave_requests
  add column if not exists leave_type text;

alter table public.leave_requests
  add column if not exists status text;

alter table public.leave_requests
  add column if not exists start_date date;

alter table public.leave_requests
  add column if not exists end_date date;

alter table public.leave_requests
  add column if not exists working_days integer not null default 0;

alter table public.leave_requests
  add column if not exists title text;

alter table public.leave_requests
  add column if not exists notes text;

alter table public.leave_requests
  add column if not exists created_at timestamptz not null default now();

alter table public.leave_requests
  add column if not exists updated_at timestamptz not null default now();

update public.leave_requests
set start_date = coalesce(start_date, current_date)
where start_date is null;

update public.leave_requests
set end_date = coalesce(end_date, start_date, current_date)
where end_date is null;

update public.leave_requests
set leave_type = coalesce(leave_type, 'vacation')
where leave_type is null;

update public.leave_requests
set status = coalesce(status, 'planned')
where status is null;

alter table public.leave_requests
  alter column start_date set not null;

alter table public.leave_requests
  alter column end_date set not null;

alter table public.leave_requests
  alter column leave_type set not null;

alter table public.leave_requests
  alter column status set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'leave_requests_date_order'
  ) then
    alter table public.leave_requests
      add constraint leave_requests_date_order
      check (end_date >= start_date);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'leave_requests_leave_type_check'
  ) then
    alter table public.leave_requests
      add constraint leave_requests_leave_type_check
      check (leave_type in ('vacation', 'additional'));
  end if;
end $$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'leave_requests_status_check'
  ) then
    alter table public.leave_requests
      add constraint leave_requests_status_check
      check (status in ('planned', 'used', 'cancelled'));
  end if;
end $$;

create index if not exists idx_leave_requests_user_id
  on public.leave_requests(user_id);

create index if not exists idx_leave_requests_status
  on public.leave_requests(status);

create index if not exists idx_leave_requests_start_date
  on public.leave_requests(start_date);

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
before insert or update on public.leave_requests
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