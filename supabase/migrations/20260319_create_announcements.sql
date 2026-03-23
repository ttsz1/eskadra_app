create extension if not exists pgcrypto;
create extension if not exists pg_cron;

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(trim(title)) between 3 and 160),
  content text not null check (char_length(trim(content)) between 1 and 5000),
  created_at timestamptz not null default now(),
  created_by uuid not null references auth.users(id) on delete restrict,
  auto_delete_at timestamptz null
);

create index if not exists idx_announcements_created_at
  on public.announcements (created_at desc);

create index if not exists idx_announcements_auto_delete_at
  on public.announcements (auto_delete_at);

alter table public.announcements enable row level security;

drop policy if exists "announcements_select_authenticated" on public.announcements;
create policy "announcements_select_authenticated"
on public.announcements
for select
to authenticated
using (
  auto_delete_at is null
  or auto_delete_at > now()
);

drop policy if exists "announcements_insert_authenticated" on public.announcements;
create policy "announcements_insert_authenticated"
on public.announcements
for insert
to authenticated
with check (
  created_by = auth.uid()
);

drop policy if exists "announcements_delete_creator" on public.announcements;
create policy "announcements_delete_creator"
on public.announcements
for delete
to authenticated
using (
  created_by = auth.uid()
);

create or replace function public.set_announcement_created_by()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.created_by is null then
    new.created_by := auth.uid();
  end if;
  return new;
end;
$$;

drop trigger if exists trg_set_announcement_created_by on public.announcements;
create trigger trg_set_announcement_created_by
before insert on public.announcements
for each row
execute function public.set_announcement_created_by();

create or replace function public.delete_expired_announcements()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  deleted_count integer;
begin
  delete from public.announcements
  where auto_delete_at is not null
    and auto_delete_at <= now();

  get diagnostics deleted_count = row_count;
  return deleted_count;
end;
$$;

-- Odpalić tylko raz. Jeżeli job już istnieje, najpierw:
-- select cron.unschedule('delete-expired-announcements');

select cron.schedule(
  'delete-expired-announcements',
  '*/15 * * * *',
  $$select public.delete_expired_announcements();$$
);