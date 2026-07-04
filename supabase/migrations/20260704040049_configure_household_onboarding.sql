-- Persist and safely complete the owner's household setup.

alter table public.households
  add column setup_completed boolean not null default false,
  add constraint households_currency_iso_code
    check (currency ~ '^[A-Z]{3}$');

create or replace function public.prevent_unsafe_household_currency_change()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if old.currency is distinct from new.currency
    and (
      exists (select 1 from public.transactions as t
              where t.household_id = old.id)
      or exists (select 1 from public.budgets as b
                 where b.household_id = old.id)
      or exists (select 1 from public.goals as g
                 where g.household_id = old.id)
      or exists (select 1 from public.subscriptions as s
                 where s.household_id = old.id)
    ) then
    raise exception using
      errcode = 'P0001',
      message = 'currency_change_requires_empty_household';
  end if;
  return new;
end;
$$;

create trigger prevent_unsafe_household_currency_change
  before update of currency on public.households
  for each row execute function public.prevent_unsafe_household_currency_change();

revoke all on function public.prevent_unsafe_household_currency_change()
  from public, anon;
grant execute on function public.prevent_unsafe_household_currency_change()
  to authenticated;

create or replace function public.configure_household(
  p_household_id uuid,
  p_name text,
  p_currency text
)
returns table (
  id uuid,
  name text,
  owner_id uuid,
  currency text,
  setup_completed boolean,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
security invoker
set search_path = ''
as $$
#variable_conflict use_column
declare
  caller_id uuid := auth.uid();
  normalized_name text := btrim(p_name);
  normalized_currency text := upper(btrim(p_currency));
  household public.households%rowtype;
begin
  if caller_id is null then
    raise exception using errcode = 'P0001', message = 'authentication_required';
  end if;

  if normalized_name is null
    or normalized_name = ''
    or char_length(normalized_name) > 80 then
    raise exception using errcode = 'P0001', message = 'invalid_household_name';
  end if;

  if normalized_currency is null
    or normalized_currency !~ '^[A-Z]{3}$' then
    raise exception using errcode = 'P0001', message = 'invalid_currency';
  end if;

  select h.*
  into household
  from public.households as h
  where h.id = p_household_id
    and h.owner_id = caller_id
  for update;

  if not found then
    raise exception using errcode = 'P0001', message = 'not_household_owner';
  end if;

  if household.currency <> normalized_currency
    and (
      exists (select 1 from public.transactions as t
              where t.household_id = household.id)
      or exists (select 1 from public.budgets as b
                 where b.household_id = household.id)
      or exists (select 1 from public.goals as g
                 where g.household_id = household.id)
      or exists (select 1 from public.subscriptions as s
                 where s.household_id = household.id)
    ) then
    raise exception using
      errcode = 'P0001',
      message = 'currency_change_requires_empty_household';
  end if;

  update public.households as h
  set name = normalized_name,
      currency = normalized_currency,
      setup_completed = true
  where h.id = household.id
  returning h.* into household;

  -- Keep the owner's existing profile preference aligned with the household
  -- selected during first-run setup. Other members retain their own preference.
  update public.profiles as p
  set currency = normalized_currency
  where p.id = caller_id;

  return query
  select household.id,
         household.name,
         household.owner_id,
         household.currency,
         household.setup_completed,
         household.created_at,
         household.updated_at;
end;
$$;

revoke all on function public.configure_household(uuid, text, text)
  from public, anon;
grant execute on function public.configure_household(uuid, text, text)
  to authenticated;
