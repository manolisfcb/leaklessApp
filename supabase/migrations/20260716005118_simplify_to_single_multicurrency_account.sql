-- A household has one financial container. Transactions keep their original
-- currency and immutable reporting snapshot; an account no longer represents
-- a currency wallet.

drop index if exists public.accounts_one_default_per_currency_idx;
create unique index accounts_one_active_per_household_idx
  on public.accounts(household_id)
  where not is_archived;

create or replace function public.fill_transaction_financial_defaults()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare reporting text;
begin
  select h.currency into reporting
  from public.households h
  where h.id = new.household_id;

  if auth.uid() is not null
     and not public.is_household_member(new.household_id) then
    raise exception using errcode = '42501', message = 'not_household_member';
  end if;

  if new.account_id is null then
    select a.id into new.account_id
    from public.accounts a
    where a.household_id = new.household_id and not a.is_archived
    order by a.is_default desc, a.created_at
    limit 1;
  end if;

  if new.currency = reporting then
    new.reporting_currency := coalesce(new.reporting_currency, reporting);
    new.exchange_rate_to_reporting := coalesce(new.exchange_rate_to_reporting, 1);
    new.exchange_rate_date := coalesce(new.exchange_rate_date, new.occurred_at::date);
    new.exchange_rate_source := coalesce(new.exchange_rate_source, 'identity');
    new.amount_reporting := coalesce(new.amount_reporting, new.amount);
  end if;
  return new;
end;
$$;

create or replace function public.fill_subscription_account_default()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if new.account_id is null then
    select a.id into new.account_id
    from public.accounts a
    where a.household_id = new.household_id and not a.is_archived
    order by a.is_default desc, a.created_at
    limit 1;
  end if;
  return new;
end;
$$;

create or replace function public.validate_financial_relationships()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  account_row public.accounts%rowtype;
  source_row public.income_sources%rowtype;
begin
  select * into account_row from public.accounts where id = new.account_id;
  if not found or account_row.household_id <> new.household_id then
    raise exception using errcode = '23514', message = 'account_household_mismatch';
  end if;

  if new.income_source_id is not null then
    select * into source_row
    from public.income_sources
    where id = new.income_source_id;
    if not found or source_row.household_id <> new.household_id then
      raise exception using errcode = '23514', message = 'income_source_household_mismatch';
    end if;
  end if;
  return new;
end;
$$;

create or replace function public.validate_income_source_account()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if new.default_account_id is not null and not exists (
    select 1 from public.accounts a
    where a.id = new.default_account_id
      and a.household_id = new.household_id
      and not a.is_archived
  ) then
    raise exception using errcode = '23514', message = 'income_source_account_mismatch';
  end if;
  return new;
end;
$$;
