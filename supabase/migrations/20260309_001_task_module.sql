-- =========================================================
-- TASK MODULE / ORG / SECURITY FOUNDATION
-- =========================================================

create extension if not exists pgcrypto;

-- ---------------------------------------------------------
-- 1. ENUMS
-- ---------------------------------------------------------

do $$
begin
  if not exists (select 1 from pg_type where typname = 'org_unit_enum') then
    create type public.org_unit_enum as enum (
      'command',
      'flight_training_section',
      'standardization_and_evaluation_section',
      'current_operations_section',
      'wys_rat_support_section',
      'trainer_device_support',
      'flight_training_subunit'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'org_function_enum') then
    create type public.org_function_enum as enum (
      'commander',
      'chief',
      'manager',
      'personnel'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'personnel_type_enum') then
    create type public.personnel_type_enum as enum (
      'pilot',
      'ground_staff'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'rank_group_enum') then
    create type public.rank_group_enum as enum (
      'officer',
      'non_commissioned_officer',
      'enlisted'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'task_priority_enum') then
    create type public.task_priority_enum as enum (
      'low',
      'normal',
      'urgent',
      'very_urgent'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'task_status_enum') then
    create type public.task_status_enum as enum (
      'unassigned',
      'new_task',
      'in_progress',
      'waiting',
      'completed',
      'cancelled'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'task_recurrence_enum') then
    create type public.task_recurrence_enum as enum (
      'none',
      'daily',
      'weekly',
      'monthly',
      'quarterly',
      'semi_annual',
      'yearly'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'task_reminder_enum') then
    create type public.task_reminder_enum as enum (
      'none',
      'minutes_15',
      'minutes_30',
      'hour_1',
      'hours_3',
      'day_1',
      'days_2'
    );
  end if;
end
$$;

-- ---------------------------------------------------------
-- 2. PROFILES
-- ---------------------------------------------------------

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique,
  full_name text not null,
  org_unit public.org_unit_enum not null,
  org_function public.org_function_enum not null,
  personnel_type public.personnel_type_enum not null,
  rank_group public.rank_group_enum not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_set_updated_at on public.profiles;
create trigger trg_profiles_set_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    email,
    full_name,
    org_unit,
    org_function,
    personnel_type,
    rank_group
  )
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', coalesce(new.email, 'Użytkownik')),
    coalesce((new.raw_user_meta_data ->> 'org_unit')::public.org_unit_enum, 'command'),
    coalesce((new.raw_user_meta_data ->> 'org_function')::public.org_function_enum, 'personnel'),
    coalesce((new.raw_user_meta_data ->> 'personnel_type')::public.personnel_type_enum, 'ground_staff'),
    coalesce((new.raw_user_meta_data ->> 'rank_group')::public.rank_group_enum, 'enlisted')
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();

-- ---------------------------------------------------------
-- 3. TASKS
-- ---------------------------------------------------------

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(trim(title)) between 3 and 200),
  description text not null default '',
  created_by uuid not null references public.profiles(id) on delete restrict,
  responsible_person_id uuid references public.profiles(id) on delete set null,
  section_unit public.org_unit_enum,
  priority public.task_priority_enum not null default 'normal',
  status public.task_status_enum not null default 'unassigned',
  is_secret boolean not null default false,
  attachment_name text,
  attachment_path text,
  reminder_option public.task_reminder_enum not null default 'none',
  recurrence public.task_recurrence_enum not null default 'none',
  deadline timestamptz not null,
  completed_at timestamptz,
  cancellation_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_tasks_set_updated_at on public.tasks;
create trigger trg_tasks_set_updated_at
before update on public.tasks
for each row
execute function public.set_updated_at();

create or replace function public.sync_task_section_from_responsible()
returns trigger
language plpgsql
as $$
begin
  if new.responsible_person_id is null then
    new.section_unit = null;

    if new.status = 'new_task' then
      new.status = 'unassigned';
    end if;

    return new;
  end if;

  select p.org_unit
  into new.section_unit
  from public.profiles p
  where p.id = new.responsible_person_id;

  if new.status = 'unassigned' then
    new.status = 'new_task';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_tasks_sync_section on public.tasks;
create trigger trg_tasks_sync_section
before insert or update of responsible_person_id, status
on public.tasks
for each row
execute function public.sync_task_section_from_responsible();

create or replace function public.sync_task_completed_at()
returns trigger
language plpgsql
as $$
begin
  if new.status = 'completed' and old.status is distinct from 'completed' then
    new.completed_at = now();
  end if;

  if new.status <> 'completed' then
    new.completed_at = null;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_tasks_sync_completed_at on public.tasks;
create trigger trg_tasks_sync_completed_at
before update of status
on public.tasks
for each row
execute function public.sync_task_completed_at();

-- ---------------------------------------------------------
-- 4. TASK HELPERS / NOTES / LOGS / SECRET ACCESS / REMINDERS
-- ---------------------------------------------------------

create table if not exists public.task_helpers (
  task_id uuid not null references public.tasks(id) on delete cascade,
  person_id uuid not null references public.profiles(id) on delete cascade,
  added_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  primary key (task_id, person_id)
);

create table if not exists public.task_notes (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete restrict,
  content text not null check (char_length(trim(content)) > 0),
  created_at timestamptz not null default now()
);

create table if not exists public.task_note_mentions (
  task_note_id uuid not null references public.task_notes(id) on delete cascade,
  person_id uuid not null references public.profiles(id) on delete cascade,
  primary key (task_note_id, person_id)
);

create table if not exists public.task_logs (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks(id) on delete cascade,
  actor_id uuid not null references public.profiles(id) on delete restrict,
  message text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.task_secret_units (
  task_id uuid not null references public.tasks(id) on delete cascade,
  org_unit public.org_unit_enum not null,
  primary key (task_id, org_unit)
);

create table if not exists public.task_secret_people (
  task_id uuid not null references public.tasks(id) on delete cascade,
  person_id uuid not null references public.profiles(id) on delete cascade,
  primary key (task_id, person_id)
);

create table if not exists public.task_secret_personnel_types (
  task_id uuid not null references public.tasks(id) on delete cascade,
  personnel_type public.personnel_type_enum not null,
  primary key (task_id, personnel_type)
);

create table if not exists public.task_secret_rank_groups (
  task_id uuid not null references public.tasks(id) on delete cascade,
  rank_group public.rank_group_enum not null,
  primary key (task_id, rank_group)
);

create table if not exists public.task_reminders (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks(id) on delete cascade,
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  reminder_at timestamptz not null,
  channel text not null default 'email' check (channel in ('email')),
  sent_at timestamptz,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- 5. INDEXES
-- ---------------------------------------------------------

create index if not exists idx_profiles_org_unit on public.profiles(org_unit);
create index if not exists idx_profiles_personnel_type on public.profiles(personnel_type);
create index if not exists idx_profiles_rank_group on public.profiles(rank_group);

create index if not exists idx_tasks_created_by on public.tasks(created_by);
create index if not exists idx_tasks_responsible on public.tasks(responsible_person_id);
create index if not exists idx_tasks_section on public.tasks(section_unit);
create index if not exists idx_tasks_status on public.tasks(status);
create index if not exists idx_tasks_deadline on public.tasks(deadline);
create index if not exists idx_tasks_completed_at on public.tasks(completed_at);
create index if not exists idx_tasks_is_secret on public.tasks(is_secret);

create index if not exists idx_task_helpers_person on public.task_helpers(person_id);
create index if not exists idx_task_notes_task on public.task_notes(task_id);
create index if not exists idx_task_logs_task on public.task_logs(task_id);
create index if not exists idx_task_reminders_task on public.task_reminders(task_id);
create index if not exists idx_task_reminders_recipient on public.task_reminders(recipient_id);
create index if not exists idx_task_reminders_due on public.task_reminders(reminder_at) where sent_at is null;

-- ---------------------------------------------------------
-- 6. ACCESS HELPERS
-- ---------------------------------------------------------

create or replace function public.current_profile_id()
returns uuid
language sql
stable
as $$
  select auth.uid();
$$;

create or replace function public.can_access_task(p_task_id uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_task public.tasks%rowtype;
  v_user public.profiles%rowtype;
  v_structure_filter_active boolean;
  v_tag_filter_active boolean;
  v_structure_match boolean;
  v_tag_match boolean;
begin
  if v_user_id is null then
    return false;
  end if;

  select *
  into v_task
  from public.tasks
  where id = p_task_id;

  if not found then
    return false;
  end if;

  if not v_task.is_secret then
    return true;
  end if;

  if v_task.created_by = v_user_id or v_task.responsible_person_id = v_user_id then
    return true;
  end if;

  if exists (
    select 1
    from public.task_helpers h
    where h.task_id = p_task_id
      and h.person_id = v_user_id
  ) then
    return true;
  end if;

  select *
  into v_user
  from public.profiles
  where id = v_user_id;

  if not found then
    return false;
  end if;

  v_structure_filter_active :=
    exists (select 1 from public.task_secret_units u where u.task_id = p_task_id) or
    exists (select 1 from public.task_secret_people p where p.task_id = p_task_id);

  v_tag_filter_active :=
    exists (select 1 from public.task_secret_personnel_types t where t.task_id = p_task_id) or
    exists (select 1 from public.task_secret_rank_groups r where r.task_id = p_task_id);

  v_structure_match :=
    not v_structure_filter_active
    or exists (
      select 1
      from public.task_secret_units u
      where u.task_id = p_task_id
        and u.org_unit = v_user.org_unit
    )
    or exists (
      select 1
      from public.task_secret_people p
      where p.task_id = p_task_id
        and p.person_id = v_user_id
    );

  v_tag_match :=
    (
      not exists (select 1 from public.task_secret_personnel_types t where t.task_id = p_task_id)
      or exists (
        select 1
        from public.task_secret_personnel_types t
        where t.task_id = p_task_id
          and t.personnel_type = v_user.personnel_type
      )
    )
    and
    (
      not exists (select 1 from public.task_secret_rank_groups r where r.task_id = p_task_id)
      or exists (
        select 1
        from public.task_secret_rank_groups r
        where r.task_id = p_task_id
          and r.rank_group = v_user.rank_group
      )
    );

  return v_structure_match and v_tag_match;
end;
$$;

-- ---------------------------------------------------------
-- 7. LOGGING HELPERS
-- ---------------------------------------------------------

create or replace function public.add_task_log(
  p_task_id uuid,
  p_actor_id uuid,
  p_message text
)
returns void
language sql
security definer
set search_path = public
as $$
  insert into public.task_logs (task_id, actor_id, message)
  values (p_task_id, p_actor_id, p_message);
$$;

-- ---------------------------------------------------------
-- 8. STORAGE
-- ---------------------------------------------------------

insert into storage.buckets (id, name, public)
values ('task-attachments', 'task-attachments', false)
on conflict (id) do nothing;

-- ---------------------------------------------------------
-- 9. RLS
-- ---------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.tasks enable row level security;
alter table public.task_helpers enable row level security;
alter table public.task_notes enable row level security;
alter table public.task_note_mentions enable row level security;
alter table public.task_logs enable row level security;
alter table public.task_secret_units enable row level security;
alter table public.task_secret_people enable row level security;
alter table public.task_secret_personnel_types enable row level security;
alter table public.task_secret_rank_groups enable row level security;
alter table public.task_reminders enable row level security;

-- profiles
drop policy if exists profiles_select_authenticated on public.profiles;
create policy profiles_select_authenticated
on public.profiles
for select
to authenticated
using (true);

drop policy if exists profiles_update_self on public.profiles;
create policy profiles_update_self
on public.profiles
for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

-- tasks
drop policy if exists tasks_select_accessible on public.tasks;
create policy tasks_select_accessible
on public.tasks
for select
to authenticated
using (public.can_access_task(id));

drop policy if exists tasks_insert_authenticated on public.tasks;
create policy tasks_insert_authenticated
on public.tasks
for insert
to authenticated
with check (created_by = auth.uid());

drop policy if exists tasks_update_accessible on public.tasks;
create policy tasks_update_accessible
on public.tasks
for update
to authenticated
using (public.can_access_task(id))
with check (public.can_access_task(id));

drop policy if exists tasks_delete_creator_or_responsible on public.tasks;
create policy tasks_delete_creator_or_responsible
on public.tasks
for delete
to authenticated
using (
  created_by = auth.uid() or responsible_person_id = auth.uid()
);

-- helpers
drop policy if exists task_helpers_select_accessible on public.task_helpers;
create policy task_helpers_select_accessible
on public.task_helpers
for select
to authenticated
using (public.can_access_task(task_id));

drop policy if exists task_helpers_insert_accessible on public.task_helpers;
create policy task_helpers_insert_accessible
on public.task_helpers
for insert
to authenticated
with check (
  public.can_access_task(task_id)
  and added_by = auth.uid()
);

drop policy if exists task_helpers_delete_accessible on public.task_helpers;
create policy task_helpers_delete_accessible
on public.task_helpers
for delete
to authenticated
using (public.can_access_task(task_id));

-- notes
drop policy if exists task_notes_select_accessible on public.task_notes;
create policy task_notes_select_accessible
on public.task_notes
for select
to authenticated
using (public.can_access_task(task_id));

drop policy if exists task_notes_insert_accessible on public.task_notes;
create policy task_notes_insert_accessible
on public.task_notes
for insert
to authenticated
with check (
  public.can_access_task(task_id)
  and author_id = auth.uid()
);

-- note mentions
drop policy if exists task_note_mentions_select_accessible on public.task_note_mentions;
create policy task_note_mentions_select_accessible
on public.task_note_mentions
for select
to authenticated
using (
  exists (
    select 1
    from public.task_notes n
    where n.id = task_note_id
      and public.can_access_task(n.task_id)
  )
);

drop policy if exists task_note_mentions_insert_accessible on public.task_note_mentions;
create policy task_note_mentions_insert_accessible
on public.task_note_mentions
for insert
to authenticated
with check (
  exists (
    select 1
    from public.task_notes n
    where n.id = task_note_id
      and public.can_access_task(n.task_id)
  )
);

-- logs
drop policy if exists task_logs_select_accessible on public.task_logs;
create policy task_logs_select_accessible
on public.task_logs
for select
to authenticated
using (public.can_access_task(task_id));

drop policy if exists task_logs_insert_accessible on public.task_logs;
create policy task_logs_insert_accessible
on public.task_logs
for insert
to authenticated
with check (
  public.can_access_task(task_id)
  and actor_id = auth.uid()
);

-- secret access tables
drop policy if exists task_secret_units_select_accessible on public.task_secret_units;
create policy task_secret_units_select_accessible
on public.task_secret_units
for select
to authenticated
using (public.can_access_task(task_id));

drop policy if exists task_secret_units_insert_accessible on public.task_secret_units;
create policy task_secret_units_insert_accessible
on public.task_secret_units
for insert
to authenticated
with check (public.can_access_task(task_id));

drop policy if exists task_secret_units_delete_accessible on public.task_secret_units;
create policy task_secret_units_delete_accessible
on public.task_secret_units
for delete
to authenticated
using (public.can_access_task(task_id));

drop policy if exists task_secret_people_select_accessible on public.task_secret_people;
create policy task_secret_people_select_accessible
on public.task_secret_people
for select
to authenticated
using (public.can_access_task(task_id));

drop policy if exists task_secret_people_insert_accessible on public.task_secret_people;
create policy task_secret_people_insert_accessible
on public.task_secret_people
for insert
to authenticated
with check (public.can_access_task(task_id));

drop policy if exists task_secret_people_delete_accessible on public.task_secret_people;
create policy task_secret_people_delete_accessible
on public.task_secret_people
for delete
to authenticated
using (public.can_access_task(task_id));

drop policy if exists task_secret_personnel_types_select_accessible on public.task_secret_personnel_types;
create policy task_secret_personnel_types_select_accessible
on public.task_secret_personnel_types
for select
to authenticated
using (public.can_access_task(task_id));

drop policy if exists task_secret_personnel_types_insert_accessible on public.task_secret_personnel_types;
create policy task_secret_personnel_types_insert_accessible
on public.task_secret_personnel_types
for insert
to authenticated
with check (public.can_access_task(task_id));

drop policy if exists task_secret_personnel_types_delete_accessible on public.task_secret_personnel_types;
create policy task_secret_personnel_types_delete_accessible
on public.task_secret_personnel_types
for delete
to authenticated
using (public.can_access_task(task_id));

drop policy if exists task_secret_rank_groups_select_accessible on public.task_secret_rank_groups;
create policy task_secret_rank_groups_select_accessible
on public.task_secret_rank_groups
for select
to authenticated
using (public.can_access_task(task_id));

drop policy if exists task_secret_rank_groups_insert_accessible on public.task_secret_rank_groups;
create policy task_secret_rank_groups_insert_accessible
on public.task_secret_rank_groups
for insert
to authenticated
with check (public.can_access_task(task_id));

drop policy if exists task_secret_rank_groups_delete_accessible on public.task_secret_rank_groups;
create policy task_secret_rank_groups_delete_accessible
on public.task_secret_rank_groups
for delete
to authenticated
using (public.can_access_task(task_id));

-- reminders
drop policy if exists task_reminders_select_accessible on public.task_reminders;
create policy task_reminders_select_accessible
on public.task_reminders
for select
to authenticated
using (recipient_id = auth.uid() or public.can_access_task(task_id));

drop policy if exists task_reminders_insert_accessible on public.task_reminders;
create policy task_reminders_insert_accessible
on public.task_reminders
for insert
to authenticated
with check (public.can_access_task(task_id));

-- storage.objects for task-attachments
drop policy if exists task_attachments_select on storage.objects;
create policy task_attachments_select
on storage.objects
for select
to authenticated
using (
  bucket_id = 'task-attachments'
  and exists (
    select 1
    from public.tasks t
    where t.attachment_path = name
      and public.can_access_task(t.id)
  )
);

drop policy if exists task_attachments_insert on storage.objects;
create policy task_attachments_insert
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'task-attachments'
);

drop policy if exists task_attachments_update on storage.objects;
create policy task_attachments_update
on storage.objects
for update
to authenticated
using (bucket_id = 'task-attachments')
with check (bucket_id = 'task-attachments');

drop policy if exists task_attachments_delete on storage.objects;
create policy task_attachments_delete
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'task-attachments'
);

-- ---------------------------------------------------------
-- 10. VIEWS
-- ---------------------------------------------------------

create or replace view public.tasks_active as
select *
from public.tasks
where not (
  status = 'completed'
  and completed_at is not null
  and completed_at <= now() - interval '7 days'
);

create or replace view public.tasks_archive as
select *
from public.tasks
where status = 'completed'
  and completed_at is not null
  and completed_at <= now() - interval '7 days';