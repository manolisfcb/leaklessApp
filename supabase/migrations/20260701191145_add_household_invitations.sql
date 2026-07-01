-- Secure, single-use household invitations.
--
-- The plaintext token is returned exactly once by
-- create_household_invitation(). Only its SHA-256 digest is persisted. The
-- table itself is deliberately unavailable through the Data API: every read
-- or mutation goes through the narrowly-scoped RPCs below.

create table public.household_invitations (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null
    references public.households(id) on delete cascade,
  invited_email text not null,
  invited_by uuid not null
    references auth.users(id) on delete cascade,
  token_hash bytea not null unique,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'cancelled')),
  expires_at timestamptz not null,
  accepted_at timestamptz,
  accepted_by uuid references auth.users(id) on delete set null,
  cancelled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint household_invitations_email_normalized check (
    invited_email = lower(btrim(invited_email))
    and invited_email <> ''
    and char_length(invited_email) <= 320
    and position('@' in invited_email) > 1
  ),
  constraint household_invitations_token_hash_length
    check (octet_length(token_hash) = 32),
  constraint household_invitations_expiry_after_creation
    check (expires_at > created_at),
  constraint household_invitations_state_timestamps check (
    (status = 'pending'
      and accepted_at is null
      and accepted_by is null
      and cancelled_at is null)
    or
    (status = 'accepted'
      and accepted_at is not null
      and cancelled_at is null)
    or
    (status = 'cancelled'
      and accepted_at is null
      and accepted_by is null
      and cancelled_at is not null)
  )
);

create index household_invitations_household_created_idx
  on public.household_invitations (household_id, created_at desc);
create index household_invitations_invited_by_idx
  on public.household_invitations (invited_by);
create index household_invitations_pending_expiry_idx
  on public.household_invitations (expires_at)
  where status = 'pending';
create unique index household_invitations_one_pending_email_idx
  on public.household_invitations (household_id, invited_email)
  where status = 'pending';

create trigger set_household_invitations_updated_at
  before update on public.household_invitations
  for each row execute function public.set_updated_at();

alter table public.household_invitations enable row level security;

-- No policies are intentional. Even authenticated users must not query token
-- hashes or enumerate invitations directly.
revoke all on table public.household_invitations from public, anon, authenticated;

-- Direct self-insertion previously let any authenticated user join an
-- arbitrary household. Membership now comes only from trusted provisioning or
-- the validated acceptance RPC.
drop policy if exists "members self insert" on public.household_members;

create or replace function public.create_household_invitation(
  p_household_id uuid,
  p_email text,
  p_expires_in interval default interval '7 days'
)
returns table (
  invitation_id uuid,
  household_id uuid,
  invited_email text,
  status text,
  expires_at timestamptz,
  token text
)
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  caller_id uuid := auth.uid();
  normalized_email text := lower(btrim(p_email));
  caller_email text;
  secret_token text;
begin
  if caller_id is null then
    raise exception using errcode = 'P0001', message = 'authentication_required';
  end if;

  if normalized_email is null
    or normalized_email = ''
    or char_length(normalized_email) > 320
    or position('@' in normalized_email) <= 1 then
    raise exception using errcode = 'P0001', message = 'invalid_invitation_email';
  end if;

  if p_expires_in is null
    or p_expires_in < interval '5 minutes'
    or p_expires_in > interval '30 days' then
    raise exception using errcode = 'P0001', message = 'invalid_invitation_expiry';
  end if;

  select lower(btrim(u.email))
  into caller_email
  from auth.users as u
  where u.id = caller_id;

  if caller_email = normalized_email then
    raise exception using errcode = 'P0001', message = 'cannot_invite_self';
  end if;

  perform 1
  from public.households as h
  where h.id = p_household_id
    and h.owner_id = caller_id
  for share;

  if not found then
    raise exception using errcode = 'P0001', message = 'not_household_owner';
  end if;

  if exists (
    select 1
    from public.household_members as hm
    join auth.users as u on u.id = hm.user_id
    where hm.household_id = p_household_id
      and lower(btrim(u.email)) = normalized_email
  ) then
    raise exception using errcode = 'P0001', message = 'user_already_household_member';
  end if;

  secret_token := encode(extensions.gen_random_bytes(32), 'hex');

  return query
  insert into public.household_invitations as hi (
    household_id,
    invited_email,
    invited_by,
    token_hash,
    expires_at
  )
  values (
    p_household_id,
    normalized_email,
    caller_id,
    extensions.digest(secret_token, 'sha256'),
    now() + p_expires_in
  )
  on conflict (household_id, invited_email) where status = 'pending'
  do update set
    invited_by = excluded.invited_by,
    token_hash = excluded.token_hash,
    expires_at = excluded.expires_at,
    updated_at = now()
  returning
    hi.id,
    hi.household_id,
    hi.invited_email,
    hi.status,
    hi.expires_at,
    secret_token;
end;
$$;

create or replace function public.inspect_household_invitation(p_token text)
returns table (
  invitation_id uuid,
  household_id uuid,
  household_name text,
  inviter_id uuid,
  inviter_display_name text,
  invited_email text,
  status text,
  expires_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  caller_email text;
  invitation public.household_invitations%rowtype;
begin
  if caller_id is null then
    raise exception using errcode = 'P0001', message = 'authentication_required';
  end if;

  select lower(btrim(u.email))
  into caller_email
  from auth.users as u
  where u.id = caller_id;

  select hi.*
  into invitation
  from public.household_invitations as hi
  where hi.token_hash = extensions.digest(coalesce(p_token, ''), 'sha256');

  if not found then
    raise exception using errcode = 'P0001', message = 'invalid_invitation_token';
  end if;

  if caller_email is distinct from invitation.invited_email then
    raise exception using errcode = 'P0001', message = 'invitation_email_mismatch';
  end if;

  return query
  select
    invitation.id,
    invitation.household_id,
    h.name,
    invitation.invited_by,
    coalesce(p.display_name, ''),
    invitation.invited_email,
    case
      when invitation.status = 'pending' and invitation.expires_at <= now()
        then 'expired'
      else invitation.status
    end,
    invitation.expires_at
  from public.households as h
  left join public.profiles as p on p.id = invitation.invited_by
  where h.id = invitation.household_id;
end;
$$;

create or replace function public.cancel_household_invitation(p_invitation_id uuid)
returns table (
  invitation_id uuid,
  household_id uuid,
  status text,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  invitation public.household_invitations%rowtype;
begin
  if caller_id is null then
    raise exception using errcode = 'P0001', message = 'authentication_required';
  end if;

  select hi.*
  into invitation
  from public.household_invitations as hi
  where hi.id = p_invitation_id
  for update;

  if not found then
    raise exception using errcode = 'P0001', message = 'invitation_not_found';
  end if;

  if not exists (
    select 1
    from public.households as h
    where h.id = invitation.household_id
      and h.owner_id = caller_id
  ) then
    raise exception using errcode = 'P0001', message = 'not_household_owner';
  end if;

  if invitation.status = 'accepted' then
    raise exception using errcode = 'P0001', message = 'accepted_invitation_cannot_be_cancelled';
  end if;

  if invitation.status = 'pending' then
    update public.household_invitations as hi
    set status = 'cancelled', cancelled_at = now()
    where hi.id = invitation.id
    returning hi.* into invitation;
  end if;

  return query
  select invitation.id, invitation.household_id, invitation.status,
    invitation.updated_at;
end;
$$;

create or replace function public.accept_household_invitation(p_token text)
returns table (
  invitation_id uuid,
  household_id uuid,
  status text,
  accepted_at timestamptz,
  already_accepted boolean
)
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  caller_id uuid := auth.uid();
  caller_email text;
  invitation public.household_invitations%rowtype;
  user_profile public.profiles%rowtype;
  starter_household public.households%rowtype;
begin
  if caller_id is null then
    raise exception using errcode = 'P0001', message = 'authentication_required';
  end if;

  select lower(btrim(u.email))
  into caller_email
  from auth.users as u
  where u.id = caller_id;

  select hi.*
  into invitation
  from public.household_invitations as hi
  where hi.token_hash = extensions.digest(coalesce(p_token, ''), 'sha256')
  for update;

  if not found then
    raise exception using errcode = 'P0001', message = 'invalid_invitation_token';
  end if;

  if caller_email is distinct from invitation.invited_email then
    raise exception using errcode = 'P0001', message = 'invitation_email_mismatch';
  end if;

  if invitation.status = 'accepted' then
    if invitation.accepted_by = caller_id
      and exists (
        select 1 from public.profiles as p
        where p.id = caller_id and p.household_id = invitation.household_id
      )
      and exists (
        select 1 from public.household_members as hm
        where hm.user_id = caller_id
          and hm.household_id = invitation.household_id
      ) then
      return query
      select invitation.id, invitation.household_id, invitation.status,
        invitation.accepted_at, true;
      return;
    end if;

    raise exception using errcode = 'P0001', message = 'invitation_already_used';
  end if;

  if invitation.status = 'cancelled' then
    raise exception using errcode = 'P0001', message = 'invitation_cancelled';
  end if;

  if invitation.expires_at <= now() then
    raise exception using errcode = 'P0001', message = 'invitation_expired';
  end if;

  select p.*
  into user_profile
  from public.profiles as p
  where p.id = caller_id
  for update;

  if not found then
    raise exception using errcode = 'P0001', message = 'profile_not_found';
  end if;

  if user_profile.household_id is distinct from invitation.household_id then
    select h.*
    into starter_household
    from public.households as h
    where h.id = user_profile.household_id
    for update;

    if not found
      or starter_household.owner_id <> caller_id
      or starter_household.name <> 'Nuestra casa'
      or starter_household.currency <> 'USD'
      or (select count(*) from public.household_members as hm
          where hm.household_id = starter_household.id) <> 1
      or not exists (
        select 1 from public.household_members as hm
        where hm.household_id = starter_household.id
          and hm.user_id = caller_id
          and hm.role = 'owner'
      )
      or (select count(*) from public.categories as c
          where c.household_id = starter_household.id) <> 6
      or exists (
        select 1 from public.categories as c
        where c.household_id = starter_household.id and not c.is_default
      )
      or (select count(*) from public.categories as c
          where c.household_id = starter_household.id
            and c.color_hex is null
            and (c.name, c.icon_name) in (
              ('Supermercado', 'cart'),
              ('Restaurantes', 'restaurant'),
              ('Transporte', 'car'),
              ('Ocio', 'movie'),
              ('Suscripciones', 'subscriptions'),
              ('Ahorro', 'savings')
            )) <> 6
      or not (
        select coalesce(array_agg(c.name), array[]::text[]) @> array[
          'Supermercado', 'Restaurantes', 'Transporte',
          'Ocio', 'Suscripciones', 'Ahorro'
        ]::text[]
        from public.categories as c
        where c.household_id = starter_household.id
      )
      or exists (select 1 from public.transactions as t
                 where t.household_id = starter_household.id)
      or exists (select 1 from public.budgets as b
                 where b.household_id = starter_household.id)
      or exists (select 1 from public.goals as g
                 where g.household_id = starter_household.id)
      or exists (select 1 from public.subscriptions as s
                 where s.household_id = starter_household.id)
      or exists (select 1 from public.notification_events as n
                 where n.household_id = starter_household.id)
      or exists (select 1 from public.household_invitations as hi
                 where hi.household_id = starter_household.id) then
      raise exception using errcode = 'P0001', message = 'current_household_not_empty';
    end if;

    delete from public.households as h where h.id = starter_household.id;
  end if;

  insert into public.household_members (
    household_id,
    user_id,
    display_name,
    role,
    avatar_url
  )
  values (
    invitation.household_id,
    caller_id,
    user_profile.display_name,
    'member',
    user_profile.avatar_url
  )
  on conflict (household_id, user_id) do nothing;

  update public.profiles as p
  set household_id = invitation.household_id
  where p.id = caller_id;

  update public.household_invitations as hi
  set status = 'accepted', accepted_at = now(), accepted_by = caller_id
  where hi.id = invitation.id
  returning hi.* into invitation;

  return query
  select invitation.id, invitation.household_id, invitation.status,
    invitation.accepted_at, false;
end;
$$;

revoke all on function public.create_household_invitation(uuid, text, interval)
  from public, anon;
revoke all on function public.inspect_household_invitation(text)
  from public, anon;
revoke all on function public.cancel_household_invitation(uuid)
  from public, anon;
revoke all on function public.accept_household_invitation(text)
  from public, anon;

grant execute on function public.create_household_invitation(uuid, text, interval)
  to authenticated;
grant execute on function public.inspect_household_invitation(text)
  to authenticated;
grant execute on function public.cancel_household_invitation(uuid)
  to authenticated;
grant execute on function public.accept_household_invitation(text)
  to authenticated;
