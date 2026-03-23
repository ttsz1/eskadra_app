-- =========================================
-- CHAT FEATURE
-- =========================================

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.chat_rooms (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text null unique,
  is_private boolean not null default false,
  is_global boolean not null default false,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger trg_chat_rooms_updated_at
before update on public.chat_rooms
for each row
execute function public.set_updated_at();

create table if not exists public.chat_room_members (
  room_id uuid not null references public.chat_rooms(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  added_by uuid null references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  primary key (room_id, user_id)
);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.chat_rooms(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete restrict,
  content text not null default '',
  created_at timestamptz not null default now(),
  edited_at timestamptz null
);

create index if not exists idx_chat_messages_room_created_at
  on public.chat_messages(room_id, created_at desc);

create table if not exists public.chat_attachments (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.chat_messages(id) on delete cascade,
  room_id uuid not null references public.chat_rooms(id) on delete cascade,
  file_name text not null,
  storage_path text not null,
  mime_type text null,
  file_size_bytes bigint null,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now()
);

create index if not exists idx_chat_attachments_message_id
  on public.chat_attachments(message_id);

-- =========================================
-- HELPERS
-- =========================================

create or replace function public.is_chat_member(target_room_id uuid, target_user_id uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.chat_room_members m
    where m.room_id = target_room_id
      and m.user_id = target_user_id
  );
$$;

create or replace function public.can_access_chat_room(target_room_id uuid, target_user_id uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.chat_rooms r
    where r.id = target_room_id
      and (
        r.is_global = true
        or public.is_chat_member(target_room_id, target_user_id)
      )
  );
$$;

-- =========================================
-- RLS
-- =========================================

alter table public.chat_rooms enable row level security;
alter table public.chat_room_members enable row level security;
alter table public.chat_messages enable row level security;
alter table public.chat_attachments enable row level security;

-- chat_rooms
drop policy if exists "chat_rooms_select" on public.chat_rooms;
create policy "chat_rooms_select"
on public.chat_rooms
for select
to authenticated
using (
  is_global = true
  or public.is_chat_member(id, auth.uid())
);

drop policy if exists "chat_rooms_insert" on public.chat_rooms;
create policy "chat_rooms_insert"
on public.chat_rooms
for insert
to authenticated
with check (
  created_by = auth.uid()
);

drop policy if exists "chat_rooms_update" on public.chat_rooms;
create policy "chat_rooms_update"
on public.chat_rooms
for update
to authenticated
using (
  created_by = auth.uid()
  or public.is_chat_member(id, auth.uid())
)
with check (
  created_by = created_by
);

-- chat_room_members
drop policy if exists "chat_room_members_select" on public.chat_room_members;
create policy "chat_room_members_select"
on public.chat_room_members
for select
to authenticated
using (
  public.can_access_chat_room(room_id, auth.uid())
);

drop policy if exists "chat_room_members_insert" on public.chat_room_members;
create policy "chat_room_members_insert"
on public.chat_room_members
for insert
to authenticated
with check (
  public.can_access_chat_room(room_id, auth.uid())
  and added_by = auth.uid()
);

drop policy if exists "chat_room_members_delete" on public.chat_room_members;
create policy "chat_room_members_delete"
on public.chat_room_members
for delete
to authenticated
using (
  public.can_access_chat_room(room_id, auth.uid())
);

-- chat_messages
drop policy if exists "chat_messages_select" on public.chat_messages;
create policy "chat_messages_select"
on public.chat_messages
for select
to authenticated
using (
  public.can_access_chat_room(room_id, auth.uid())
);

drop policy if exists "chat_messages_insert" on public.chat_messages;
create policy "chat_messages_insert"
on public.chat_messages
for insert
to authenticated
with check (
  sender_id = auth.uid()
  and public.can_access_chat_room(room_id, auth.uid())
);

drop policy if exists "chat_messages_update" on public.chat_messages;
create policy "chat_messages_update"
on public.chat_messages
for update
to authenticated
using (
  sender_id = auth.uid()
)
with check (
  sender_id = auth.uid()
);

-- chat_attachments
drop policy if exists "chat_attachments_select" on public.chat_attachments;
create policy "chat_attachments_select"
on public.chat_attachments
for select
to authenticated
using (
  public.can_access_chat_room(room_id, auth.uid())
);

drop policy if exists "chat_attachments_insert" on public.chat_attachments;
create policy "chat_attachments_insert"
on public.chat_attachments
for insert
to authenticated
with check (
  created_by = auth.uid()
  and public.can_access_chat_room(room_id, auth.uid())
);

-- =========================================
-- STORAGE BUCKET
-- =========================================

insert into storage.buckets (id, name, public)
values ('chat-attachments', 'chat-attachments', false)
on conflict (id) do nothing;

drop policy if exists "chat_storage_select" on storage.objects;
create policy "chat_storage_select"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'chat-attachments'
);

drop policy if exists "chat_storage_insert" on storage.objects;
create policy "chat_storage_insert"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'chat-attachments'
);

drop policy if exists "chat_storage_update" on storage.objects;
create policy "chat_storage_update"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'chat-attachments'
)
with check (
  bucket_id = 'chat-attachments'
);

drop policy if exists "chat_storage_delete" on storage.objects;
create policy "chat_storage_delete"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'chat-attachments'
);

-- =========================================
-- GLOBAL ROOM
-- =========================================

insert into public.chat_rooms (
  name,
  slug,
  is_private,
  is_global,
  created_by
)
select
  'Czat wszyscy',
  'everyone',
  false,
  true,
  id
from auth.users
order by created_at
limit 1
on conflict (slug) do nothing;