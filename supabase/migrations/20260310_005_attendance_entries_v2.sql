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

create table if not exists public.attendance_entries (
  id uuid primary key default gen_random_uuid(),

  person_id uuid not null
    references public.profiles(id) on delete cascade,

  attendance_date date not null,
  attendance_type public.attendance_type_enum not null,

  is_all_day boolean not null default false,
  time_from time,
  time_to time,

  note text not null default '',

  created_by uuid not null
    references public.profiles(id) on delete restrict,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint attendance_entries_time_valid
    check (
      (is_all_day = true and time_from is null and time_to is null)
      or
      (
        is_all_day = false
        and time_from is not null
        and time_to is not null
        and time_to > time_from
      )
    )
);

create index if not exists idx_attendance_entries_person_date
  on public.attendance_entries(person_id, attendance_date);

create index if not exists idx_attendance_entries_date
  on public.attendance_entries(attendance_date);

create index if not exists idx_attendance_entries_created_by
  on public.attendance_entries(created_by);

drop trigger if exists trg_attendance_entries_set_updated_at
on public.attendance_entries;

create trigger trg_attendance_entries_set_updated_at
before update on public.attendance_entries
for each row
execute function public.set_updated_at();

create or replace function public.ensure_attendance_entry_no_overlap()
returns trigger
language plpgsql
as $$
begin
  if new.is_all_day then
    if exists (
      select 1
      from public.attendance_entries e
      where e.person_id = new.person_id
        and e.attendance_date = new.attendance_date
        and e.id <> coalesce(new.id, '00000000-0000-0000-0000-000000000000'::uuid)
    ) then
      raise exception 'Dla tej osoby istnieje już wpis w tym dniu.';
    end if;

    return new;
  end if;

  if exists (
    select 1
    from public.attendance_entries e
    where e.person_id = new.person_id
      and e.attendance_date = new.attendance_date
      and e.id <> coalesce(new.id, '00000000-0000-0000-0000-000000000000'::uuid)
      and (
        e.is_all_day = true
        or (
          new.time_from < e.time_to
          and new.time_to > e.time_from
        )
      )
  ) then
    raise exception 'Zakres godzin nakłada się na istniejący wpis.';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_attendance_entries_no_overlap
on public.attendance_entries;

create trigger trg_attendance_entries_no_overlap
before insert or update on public.attendance_entries
for each row
execute function public.ensure_attendance_entry_no_overlap();

alter table public.attendance_entries enable row level security;

drop policy if exists attendance_entries_select_authenticated
on public.attendance_entries;
create policy attendance_entries_select_authenticated
on public.attendance_entries
for select
to authenticated
using (true);

drop policy if exists attendance_entries_insert_authenticated
on public.attendance_entries;
create policy attendance_entries_insert_authenticated
on public.attendance_entries
for insert
to authenticated
with check (created_by = auth.uid());

drop policy if exists attendance_entries_update_creator
on public.attendance_entries;
create policy attendance_entries_update_creator
on public.attendance_entries
for update
to authenticated
using (created_by = auth.uid())
with check (created_by = auth.uid());

drop policy if exists attendance_entries_delete_creator
on public.attendance_entries;
create policy attendance_entries_delete_creator
on public.attendance_entries
for delete
to authenticated
using (created_by = auth.uid());