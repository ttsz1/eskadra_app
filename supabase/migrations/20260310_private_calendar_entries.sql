create table if not exists public.private_calendar_entries (
  id uuid primary key default gen_random_uuid(),

  owner_id uuid not null
    references public.profiles(id) on delete cascade,

  title text not null
    check (char_length(trim(title)) between 2 and 200),

  description text default '',

  starts_at timestamptz not null,
  ends_at timestamptz,

  is_all_day boolean not null default false,

  color_key text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint private_entry_valid_range
  check (
    ends_at is null or ends_at >= starts_at
  )
);

create index idx_private_calendar_entries_owner
on public.private_calendar_entries(owner_id);

create index idx_private_calendar_entries_start
on public.private_calendar_entries(starts_at);

drop trigger if exists trg_private_entries_set_updated_at
on public.private_calendar_entries;

create trigger trg_private_entries_set_updated_at
before update on public.private_calendar_entries
for each row
execute function public.set_updated_at();