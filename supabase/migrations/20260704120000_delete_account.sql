-- Secure account deletion with owner transfer (F2-T8).
--
-- Danger this guards against: `households.owner_id` and `household_members`
-- both reference `auth.users(id) ON DELETE CASCADE`. Deleting the owner of a
-- *shared* household would therefore cascade-delete the household and every
-- row the partner still relies on. This RPC transfers ownership of any shared
-- household to a remaining member *before* removing the caller, so the auth
-- cascade only ever deletes the leaving user's own rows.
--
-- A *solo* household (the caller is the only member) is different: deleting the
-- account necessarily deletes the household and all of its data, so the client
-- must confirm it explicitly (`p_confirm_household_deletion => true`).

create or replace function public.delete_account(
  p_confirm_household_deletion boolean default false
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  membership record;
  member_count integer;
  new_owner uuid;
begin
  if caller_id is null then
    raise exception using errcode = 'P0001', message = 'authentication_required';
  end if;

  -- Walk every household the caller belongs to. Locking the caller's membership
  -- rows keeps a concurrent accept/transfer from racing the deletion.
  for membership in
    select hm.household_id, hm.role
    from public.household_members as hm
    where hm.user_id = caller_id
    for update
  loop
    select count(*) into member_count
    from public.household_members as hm
    where hm.household_id = membership.household_id;

    if member_count > 1 then
      -- Shared household. If the caller owns it, hand ownership to the oldest
      -- remaining member so the cascade never touches shared data. A non-owner
      -- member simply leaves.
      if membership.role = 'owner'
         or exists (
           select 1 from public.households as h
           where h.id = membership.household_id and h.owner_id = caller_id
         ) then
        select hm.user_id into new_owner
        from public.household_members as hm
        where hm.household_id = membership.household_id
          and hm.user_id <> caller_id
        order by hm.created_at asc, hm.id asc
        limit 1;

        update public.households as h
        set owner_id = new_owner
        where h.id = membership.household_id;

        update public.household_members as hm
        set role = 'owner'
        where hm.household_id = membership.household_id
          and hm.user_id = new_owner;
      end if;

      -- Detach the leaving member. Their membership row goes; the household and
      -- every other member's data stay.
      delete from public.household_members as hm
      where hm.household_id = membership.household_id
        and hm.user_id = caller_id;

    else
      -- Solo household: deletion removes the household and all of its data.
      if not p_confirm_household_deletion then
        raise exception using errcode = 'P0001',
          message = 'household_deletion_not_confirmed';
      end if;

      delete from public.households as h
      where h.id = membership.household_id;
    end if;
  end loop;

  -- Clean the caller's private avatar objects — the auth cascade does not reach
  -- Storage, so they would otherwise be orphaned.
  delete from storage.objects
  where bucket_id = 'avatars'
    and (storage.foldername(name))[1] = caller_id::text;

  -- Finally remove the auth user. Cascades drop the caller's profile, their
  -- remaining memberships, and any invitations they created. Ownership of every
  -- shared household has already been transferred, so nothing shared is lost.
  delete from auth.users where id = caller_id;
end;
$$;

revoke all on function public.delete_account(boolean) from public, anon;
grant execute on function public.delete_account(boolean) to authenticated;
