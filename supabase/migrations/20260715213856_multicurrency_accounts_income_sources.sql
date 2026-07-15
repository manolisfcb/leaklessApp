-- Multicurrency financial model: accounts, immutable reporting snapshots,
-- income sources, exchange rates and atomic transfer legs.

create table public.accounts (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  name text not null check (btrim(name) <> ''),
  currency text not null check (currency ~ '^[A-Z]{3}$'),
  kind text not null default 'checking'
    check (kind in ('cash', 'checking', 'savings', 'credit_card', 'loan', 'investment', 'other')),
  balance_nature text not null default 'asset'
    check (balance_nature in ('asset', 'liability')),
  opening_balance numeric(14, 2) not null default 0,
  opening_balance_at timestamptz not null default now(),
  icon_name text not null default 'bank',
  color_hex text,
  is_default boolean not null default false,
  is_archived boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index accounts_household_idx on public.accounts(household_id);
create unique index accounts_one_default_per_currency_idx
  on public.accounts(household_id, currency)
  where is_default and not is_archived;

create table public.income_sources (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  name text not null check (btrim(name) <> ''),
  type text not null default 'other'
    check (type in ('employment', 'business', 'freelance', 'investment', 'benefit', 'other')),
  default_currency text not null check (default_currency ~ '^[A-Z]{3}$'),
  default_account_id uuid references public.accounts(id) on delete set null,
  icon_name text not null default 'briefcase',
  color_hex text,
  is_archived boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index income_sources_household_idx on public.income_sources(household_id);
create unique index income_sources_active_name_idx
  on public.income_sources(household_id, lower(btrim(name)))
  where not is_archived;

create table public.exchange_rates (
  id uuid primary key default gen_random_uuid(),
  rate_date date not null,
  foreign_currency text not null check (foreign_currency ~ '^[A-Z]{3}$'),
  reporting_currency text not null default 'CAD'
    check (reporting_currency ~ '^[A-Z]{3}$'),
  rate numeric(20, 10) not null check (rate > 0),
  source text not null default 'bank_of_canada',
  retrieved_at timestamptz not null default now(),
  raw_observation_date date not null,
  unique (rate_date, foreign_currency, reporting_currency, source),
  check (foreign_currency <> reporting_currency)
);

create index exchange_rates_pair_date_idx
  on public.exchange_rates(foreign_currency, reporting_currency, rate_date desc);

alter table public.transactions
  add column account_id uuid references public.accounts(id) on delete restrict,
  add column reporting_currency text check (reporting_currency ~ '^[A-Z]{3}$'),
  add column exchange_rate_to_reporting numeric(20, 10)
    check (exchange_rate_to_reporting > 0),
  add column exchange_rate_date date,
  add column exchange_rate_source text,
  add column amount_reporting numeric(14, 2),
  add column income_source_id uuid references public.income_sources(id) on delete restrict,
  add column transfer_group_id uuid,
  add column transfer_direction text check (transfer_direction in ('outgoing', 'incoming'));

alter table public.subscriptions
  add column account_id uuid references public.accounts(id) on delete restrict,
  add column estimated_reporting_amount numeric(14, 2),
  add column reporting_currency text check (reporting_currency ~ '^[A-Z]{3}$'),
  add column exchange_rate_date date;

-- Existing households receive one native default account. Existing amounts are
-- already denominated in the household currency, so their reporting snapshot
-- is identity-valued. A reporting-currency change remains blocked by the
-- existing controlled household configuration trigger.
insert into public.accounts (
  household_id, name, currency, kind, opening_balance, opening_balance_at,
  icon_name, is_default
)
select h.id, 'Cuenta principal', h.currency, 'checking', 0,
       coalesce(min(t.occurred_at), h.created_at), 'bank', true
from public.households h
left join public.transactions t on t.household_id = h.id
group by h.id
on conflict do nothing;

update public.transactions t
set account_id = a.id,
    reporting_currency = h.currency,
    exchange_rate_to_reporting = 1,
    exchange_rate_date = t.occurred_at::date,
    exchange_rate_source = 'historical_identity_backfill',
    amount_reporting = t.amount
from public.households h
join public.accounts a
  on a.household_id = h.id and a.is_default and not a.is_archived
where t.household_id = h.id and t.account_id is null;

update public.subscriptions s
set account_id = a.id,
    reporting_currency = h.currency,
    estimated_reporting_amount = case
      when s.currency = h.currency then s.amount else null end
from public.households h
join public.accounts a
  on a.household_id = h.id and a.is_default and not a.is_archived
where s.household_id = h.id and s.account_id is null;

alter table public.transactions
  alter column account_id set not null,
  alter column reporting_currency set not null,
  alter column exchange_rate_to_reporting set not null,
  alter column exchange_rate_date set not null,
  alter column exchange_rate_source set not null,
  alter column amount_reporting set not null;

alter table public.subscriptions alter column account_id set not null;

-- Compatibility defaults for existing clients and database fixtures. New UI
-- always sends an account and a conversion snapshot, while this trigger keeps
-- same-currency legacy writes safe during a rolling deployment.
create or replace function public.fill_transaction_financial_defaults()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare reporting text;
begin
  select h.currency into reporting from public.households h where h.id = new.household_id;
  if auth.uid() is not null and not public.is_household_member(new.household_id) then
    raise exception using errcode = '42501', message = 'not_household_member';
  end if;
  if new.account_id is null then
    select a.id into new.account_id from public.accounts a
    where a.household_id = new.household_id and a.currency = new.currency
      and a.is_default and not a.is_archived limit 1;
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

create trigger a_fill_transaction_financial_defaults
  before insert on public.transactions for each row
  execute function public.fill_transaction_financial_defaults();

create or replace function public.fill_subscription_account_default()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if new.account_id is null then
    select a.id into new.account_id from public.accounts a
    where a.household_id = new.household_id and a.currency = new.currency
      and a.is_default and not a.is_archived limit 1;
  end if;
  return new;
end;
$$;

create trigger a_fill_subscription_account_default
  before insert on public.subscriptions for each row
  execute function public.fill_subscription_account_default();

create or replace function public.provision_household_default_account()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  insert into public.accounts (
    household_id, name, currency, kind, opening_balance,
    opening_balance_at, icon_name, is_default
  ) values (
    new.id, 'Cuenta principal', new.currency, 'checking', 0,
    new.created_at, 'bank', true
  );
  return new;
end;
$$;

create trigger provision_household_default_account
  after insert on public.households for each row
  execute function public.provision_household_default_account();

create or replace function public.sync_empty_household_account_currency()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if old.currency is distinct from new.currency then
    update public.accounts a
    set currency = new.currency
    where a.household_id = new.id
      and a.is_default
      and not exists (
        select 1 from public.transactions t where t.account_id = a.id
      );
  end if;
  return new;
end;
$$;

create trigger sync_empty_household_account_currency
  after update of currency on public.households for each row
  execute function public.sync_empty_household_account_currency();

create index transactions_account_idx on public.transactions(account_id);
create index transactions_income_source_idx on public.transactions(income_source_id);
create index transactions_transfer_group_idx on public.transactions(transfer_group_id);
create index transactions_household_currency_idx
  on public.transactions(household_id, currency, occurred_at desc);
create index subscriptions_account_idx on public.subscriptions(account_id);

alter table public.transactions add constraint transactions_kind_shape_check check (
  (type = 'income' and transfer_group_id is null and transfer_direction is null)
  or
  (type = 'expense' and income_source_id is null
    and transfer_group_id is null and transfer_direction is null)
  or
  (type = 'transfer' and income_source_id is null and category_id is null
    and transfer_group_id is not null and transfer_direction is not null)
);

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
  if account_row.currency <> new.currency then
    raise exception using errcode = '23514', message = 'account_currency_mismatch';
  end if;

  if new.income_source_id is not null then
    select * into source_row from public.income_sources where id = new.income_source_id;
    if not found or source_row.household_id <> new.household_id then
      raise exception using errcode = '23514', message = 'income_source_household_mismatch';
    end if;
  end if;
  return new;
end;
$$;

create trigger validate_transaction_financial_relationships
  before insert or update of household_id, account_id, currency, income_source_id
  on public.transactions for each row
  execute function public.validate_financial_relationships();

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
      and a.currency = new.default_currency
  ) then
    raise exception using errcode = '23514', message = 'income_source_account_mismatch';
  end if;
  return new;
end;
$$;

create trigger validate_income_source_default_account
  before insert or update of household_id, default_account_id, default_currency
  on public.income_sources for each row
  execute function public.validate_income_source_account();

create or replace function public.prevent_account_currency_change()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if old.currency is distinct from new.currency and exists (
    select 1 from public.transactions t where t.account_id = old.id
  ) then
    raise exception using errcode = '23514', message = 'account_currency_locked';
  end if;
  return new;
end;
$$;

create trigger prevent_account_currency_change
  before update of currency on public.accounts for each row
  execute function public.prevent_account_currency_change();

-- Atomic cross-currency transfer. Reporting amounts are immutable historical
-- snapshots supplied by the client after resolving the effective rate.
create or replace function public.create_account_transfer(
  p_household_id uuid,
  p_from_account_id uuid,
  p_to_account_id uuid,
  p_sent_amount numeric,
  p_received_amount numeric,
  p_reporting_currency text,
  p_sent_reporting_amount numeric,
  p_received_reporting_amount numeric,
  p_rate_date date,
  p_rate_source text,
  p_occurred_at timestamptz default now(),
  p_description text default null
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  from_account public.accounts%rowtype;
  to_account public.accounts%rowtype;
  group_id uuid := gen_random_uuid();
begin
  if auth.uid() is null or not public.is_household_member(p_household_id) then
    raise exception using errcode = '42501', message = 'not_household_member';
  end if;
  select * into from_account from public.accounts
    where id = p_from_account_id and household_id = p_household_id and not is_archived;
  select * into to_account from public.accounts
    where id = p_to_account_id and household_id = p_household_id and not is_archived;
  if from_account.id is null or to_account.id is null or from_account.id = to_account.id then
    raise exception using errcode = '23514', message = 'invalid_transfer_accounts';
  end if;
  if p_sent_amount <= 0 or p_received_amount <= 0 then
    raise exception using errcode = '23514', message = 'invalid_transfer_amount';
  end if;

  insert into public.transactions (
    household_id, account_id, amount, currency, type, priority,
    responsible_type, occurred_at, description, reporting_currency,
    exchange_rate_to_reporting, exchange_rate_date, exchange_rate_source,
    amount_reporting, transfer_group_id, transfer_direction
  ) values
  (p_household_id, from_account.id, p_sent_amount, from_account.currency,
   'transfer', 'future', 'shared', p_occurred_at, p_description,
   upper(p_reporting_currency), p_sent_reporting_amount / p_sent_amount,
   p_rate_date, p_rate_source, p_sent_reporting_amount, group_id, 'outgoing'),
  (p_household_id, to_account.id, p_received_amount, to_account.currency,
   'transfer', 'future', 'shared', p_occurred_at, p_description,
   upper(p_reporting_currency), p_received_reporting_amount / p_received_amount,
   p_rate_date, p_rate_source, p_received_reporting_amount, group_id, 'incoming');
  return group_id;
end;
$$;

alter table public.accounts enable row level security;
alter table public.income_sources enable row level security;
alter table public.exchange_rates enable row level security;

create policy "accounts household access" on public.accounts
  for all to authenticated
  using ((select public.is_household_member(household_id)))
  with check ((select public.is_household_member(household_id)));

create policy "income_sources household access" on public.income_sources
  for all to authenticated
  using ((select public.is_household_member(household_id)))
  with check ((select public.is_household_member(household_id)));

create policy "exchange_rates authenticated read" on public.exchange_rates
  for select to authenticated using (true);

grant select, insert, update, delete on public.accounts to authenticated;
grant select, insert, update, delete on public.income_sources to authenticated;
grant select on public.exchange_rates to authenticated;
revoke insert, update, delete on public.exchange_rates from anon, authenticated;

revoke all on function public.create_account_transfer(
  uuid, uuid, uuid, numeric, numeric, text, numeric, numeric, date, text,
  timestamptz, text
) from public, anon;
grant execute on function public.create_account_transfer(
  uuid, uuid, uuid, numeric, numeric, text, numeric, numeric, date, text,
  timestamptz, text
) to authenticated;

revoke all on function public.fill_transaction_financial_defaults() from public, anon, authenticated;
revoke all on function public.fill_subscription_account_default() from public, anon, authenticated;
revoke all on function public.provision_household_default_account() from public, anon, authenticated;
revoke all on function public.validate_financial_relationships() from public, anon, authenticated;
revoke all on function public.validate_income_source_account() from public, anon, authenticated;
revoke all on function public.prevent_account_currency_change() from public, anon, authenticated;
revoke all on function public.sync_empty_household_account_currency() from public, anon, authenticated;

do $$
declare t text;
begin
  foreach t in array array['accounts', 'income_sources'] loop
    execute format('create trigger set_%1$s_updated_at before update on public.%1$s '
      'for each row execute function public.set_updated_at();', t);
  end loop;
end $$;

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.accounts;
    alter publication supabase_realtime add table public.income_sources;
  end if;
exception when duplicate_object then null;
end $$;
