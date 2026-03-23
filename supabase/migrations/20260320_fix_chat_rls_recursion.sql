drop policy if exists "chat_room_members_select" on public.chat_room_members;
drop policy if exists "chat_room_members_insert" on public.chat_room_members;
drop policy if exists "chat_room_members_delete" on public.chat_room_members;

drop policy if exists "chat_rooms_select" on public.chat_rooms;
drop policy if exists "chat_rooms_update" on public.chat_rooms;

create or replace function public.is_chat_member(target_room_id uuid, target_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
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
security definer
set search_path = public
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

grant execute on function public.is_chat_member(uuid, uuid) to authenticated;
grant execute on function public.can_access_chat_room(uuid, uuid) to authenticated;

create policy "chat_rooms_select"
on public.chat_rooms
for select
to authenticated
using (
  is_global = true
  or created_by = auth.uid()
  or public.is_chat_member(id, auth.uid())
);

create policy "chat_rooms_update"
on public.chat_rooms
for update
to authenticated
using (
  created_by = auth.uid()
  or public.is_chat_member(id, auth.uid())
)
with check (
  true
);

create policy "chat_room_members_select"
on public.chat_room_members
for select
to authenticated
using (
  public.can_access_chat_room(room_id, auth.uid())
);

create policy "chat_room_members_insert"
on public.chat_room_members
for insert
to authenticated
with check (
  added_by = auth.uid()
);

create policy "chat_room_members_delete"
on public.chat_room_members
for delete
to authenticated
using (
  public.can_access_chat_room(room_id, auth.uid())
);
