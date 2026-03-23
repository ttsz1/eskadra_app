create extension if not exists pgcrypto;

do $$
begin
  if not exists (
    select 1 from pg_type where typname = 'attendance_type_enum'
  ) then
    create type public.attendance_type_enum as enum (
      'sztab',
      'loty',
      'podroz_sluzbowa',
      'inne',
      'l4',
      'sluzba',
      'po_sluzbie',
      'urlop_wypoczynkowy',
      'urlop_nagrodowy',
      'urlop_dodatkowy'
    );
  end if;
end
$$;

create table if not exists public.attendance_plans (
  id uuid primary key default gen_random_uuid(),

  created_by uuid not null
    references public.profiles(id) on delete restrict,

  attendance_type public.attendance_type_enum not null,

  date_from date not null,
  date_to date not null,

  is_all_day boolean not null default false,
  time_from time,
  time_to time,

  repeat_mode boolean not null default false,

  apply_monday boolean not null default true,
  apply_tuesday boolean not null default true,
  apply_wednesday boolean not null default true,
  apply_thursday boolean not null default true,
  apply_friday boolean not null default true,
  apply_saturday boolean not null default false,
  apply_sunday boolean not null default false,

  note text not null default '',

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint attendance_plans_date_range_valid
    check (date_to >= date_from),

  constraint attendance_plans_time_valid
    check (
      is_all_day = true
      or (
        time_from is not null
        and time_to is not null
        and time_to > time_from
      )
    )
);

create table if not exists public.attendance_plan_people (
  attendance_plan_id uuid not null
    references public.attendance_plans(id) on delete cascade,

  person_id uuid not null
    references public.profiles(id) on delete cascade,

  primary key (attendance_plan_id, person_id)
);

create index if not exists idx_attendance_plans_created_by
  on public.attendance_plans(created_by);

create index if not exists idx_attendance_plans_date_from
  on public.attendance_plans(date_from);

create index if not exists idx_attendance_plans_date_to
  on public.attendance_plans(date_to);

create index if not exists idx_attendance_plan_people_person_id
  on public.attendance_plan_people(person_id);

drop trigger if exists trg_attendance_plans_set_updated_at
on public.attendance_plans;

create trigger trg_attendance_plans_set_updated_at
before update on public.attendance_plans
for each row
execute function public.set_updated_at();

alter table public.attendance_plans enable row level security;
alter table public.attendance_plan_people enable row level security;

drop policy if exists attendance_plans_select_authenticated
on public.attendance_plans;
create policy attendance_plans_select_authenticated
on public.attendance_plans
for select
to authenticated
using (true);

drop policy if exists attendance_plans_insert_authenticated
on public.attendance_plans;
create policy attendance_plans_insert_authenticated
on public.attendance_plans
for insert
to authenticated
with check (created_by = auth.uid());

drop policy if exists attendance_plans_update_creator
on public.attendance_plans;
create policy attendance_plans_update_creator
on public.attendance_plans
for update
to authenticated
using (created_by = auth.uid())
with check (created_by = auth.uid());

drop policy if exists attendance_plans_delete_creator
on public.attendance_plans;
create policy attendance_plans_delete_creator
on public.attendance_plans
for delete
to authenticated
using (created_by = auth.uid());

drop policy if exists attendance_plan_people_select_authenticated
on public.attendance_plan_people;
create policy attendance_plan_people_select_authenticated
on public.attendance_plan_people
for select
to authenticated
using (true);

drop policy if exists attendance_plan_people_insert_authenticated
on public.attendance_plan_people;
create policy attendance_plan_people_insert_authenticated
on public.attendance_plan_people
for insert
to authenticated
with check (
  exists (
    select 1
    from public.attendance_plans p
    where p.id = attendance_plan_id
      and p.created_by = auth.uid()
  )
);

drop policy if exists attendance_plan_people_delete_authenticated
on public.attendance_plan_people;
create policy attendance_plan_people_delete_authenticated
on public.attendance_plan_people
for delete
to authenticated
using (
  exists (
    select 1
    from public.attendance_plans p
    where p.id = attendance_plan_id
      and p.created_by = auth.uid()
  )
);