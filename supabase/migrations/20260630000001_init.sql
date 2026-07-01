-- leakless — initial schema.
--
-- Tables for the shared household finance model + Row Level Security so each
-- household only sees its own data. Apply with either:
--   • Supabase SQL editor: paste & run, or
--   • Supabase CLI:        supabase link --project-ref <ref> && supabase db push
--
-- Enum-like text columns carry CHECK constraints whose values match the Dart
-- enum `.name`s used by the app mappers.

-- ---------------------------------------------------------------------------
-- helpers
-- ---------------------------------------------------------------------------
create extension if not exists "pgcrypto"; -- gen_random_uuid()

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- households
-- ---------------------------------------------------------------------------
create table if not exists public.households (
  id uuid primary key default gen_random_uuid(),
  name text not null default 'Mi hogar',
  owner_id uuid not null references auth.users(id) on delete cascade,
  currency text not null default 'USD',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- household_members
-- ---------------------------------------------------------------------------
create table if not exists public.household_members (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null default '',
  role text not null default 'member' check (role in ('owner', 'member')),
  avatar_url text,
  created_at timestamptz not null default now(),
  unique (household_id, user_id)
);
create index if not exists idx_members_household on public.household_members(household_id);
create index if not exists idx_members_user on public.household_members(user_id);

-- Membership check used by every policy. SECURITY DEFINER so it can read
-- household_members without recursing through that table's own RLS.
create or replace function public.is_household_member(hh uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.household_members m
    where m.household_id = hh and m.user_id = auth.uid()
  );
$$;

-- ---------------------------------------------------------------------------
-- profiles (one per auth user)
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  household_id uuid references public.households(id) on delete set null,
  avatar_url text,
  currency text not null default 'USD',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- categories
-- ---------------------------------------------------------------------------
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  household_id uuid references public.households(id) on delete cascade,
  name text not null,
  icon_name text not null default 'cart',
  color_hex text,
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists idx_categories_household on public.categories(household_id);

-- ---------------------------------------------------------------------------
-- transactions
-- ---------------------------------------------------------------------------
create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  amount numeric(14, 2) not null,
  currency text not null default 'USD',
  type text not null default 'expense' check (type in ('income', 'expense', 'transfer')),
  priority text not null default 'necessity'
    check (priority in ('necessity', 'lifestyle', 'future', 'ant')),
  responsible_type text not null default 'shared'
    check (responsible_type in ('me', 'partner', 'shared')),
  category_id uuid references public.categories(id) on delete set null,
  responsible_member_id uuid references public.household_members(id) on delete set null,
  description text,
  occurred_at timestamptz not null default now(),
  status text not null default 'confirmed'
    check (status in ('confirmed', 'pending')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_tx_household_date
  on public.transactions(household_id, occurred_at desc);

-- ---------------------------------------------------------------------------
-- budgets
-- ---------------------------------------------------------------------------
create table if not exists public.budgets (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  category_id uuid not null references public.categories(id) on delete cascade,
  amount_limit numeric(14, 2) not null,
  spent numeric(14, 2) not null default 0,
  currency text not null default 'USD',
  period_start date not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (household_id, category_id, period_start)
);
create index if not exists idx_budgets_household on public.budgets(household_id);

-- ---------------------------------------------------------------------------
-- goals
-- ---------------------------------------------------------------------------
create table if not exists public.goals (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  name text not null,
  target_amount numeric(14, 2) not null,
  saved_amount numeric(14, 2) not null default 0,
  currency text not null default 'USD',
  status text not null default 'active'
    check (status in ('active', 'completed', 'paused', 'archived')),
  deadline date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_goals_household on public.goals(household_id);

-- ---------------------------------------------------------------------------
-- subscriptions
-- ---------------------------------------------------------------------------
create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  name text not null,
  amount numeric(14, 2) not null,
  currency text not null default 'USD',
  status text not null default 'active'
    check (status in ('active', 'trial', 'paused', 'canceled')),
  next_charge_at timestamptz,
  category_id uuid references public.categories(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_subscriptions_household on public.subscriptions(household_id);

-- ---------------------------------------------------------------------------
-- notification_events
-- ---------------------------------------------------------------------------
create table if not exists public.notification_events (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  type text not null,
  title text not null,
  body text not null,
  actor_member_id uuid references public.household_members(id) on delete set null,
  transaction_id uuid references public.transactions(id) on delete cascade,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists idx_notifications_household
  on public.notification_events(household_id, created_at desc);

-- ---------------------------------------------------------------------------
-- updated_at triggers
-- ---------------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array[
    'households', 'profiles', 'transactions', 'budgets', 'goals', 'subscriptions'
  ] loop
    execute format('drop trigger if exists set_%1$s_updated_at on public.%1$s;', t);
    execute format(
      'create trigger set_%1$s_updated_at before update on public.%1$s '
      'for each row execute function public.set_updated_at();', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
alter table public.households          enable row level security;
alter table public.household_members   enable row level security;
alter table public.profiles            enable row level security;
alter table public.categories          enable row level security;
alter table public.transactions        enable row level security;
alter table public.budgets             enable row level security;
alter table public.goals               enable row level security;
alter table public.subscriptions       enable row level security;
alter table public.notification_events enable row level security;

-- profiles: each user manages only their own row.
drop policy if exists "profiles self access" on public.profiles;
create policy "profiles self access" on public.profiles
  for all to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- households: members can read; the owner can manage.
drop policy if exists "households read for members" on public.households;
create policy "households read for members" on public.households
  for select to authenticated using (public.is_household_member(id));

drop policy if exists "households owner manage" on public.households;
create policy "households owner manage" on public.households
  for all to authenticated
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());

-- household_members: members can read their household's members; the owner adds.
drop policy if exists "members read" on public.household_members;
create policy "members read" on public.household_members
  for select to authenticated using (public.is_household_member(household_id));

drop policy if exists "members self insert" on public.household_members;
create policy "members self insert" on public.household_members
  for insert to authenticated with check (user_id = auth.uid());

-- household-scoped tables: full access for members of the row's household.
do $$
declare t text;
begin
  foreach t in array array[
    'categories', 'transactions', 'budgets', 'goals',
    'subscriptions', 'notification_events'
  ] loop
    execute format('drop policy if exists "%1$s household access" on public.%1$s;', t);
    execute format(
      'create policy "%1$s household access" on public.%1$s for all to authenticated '
      'using (public.is_household_member(household_id)) '
      'with check (public.is_household_member(household_id));', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- Storage: private "avatars" bucket (avatars/<user-id>/...)
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', false)
on conflict (id) do nothing;

drop policy if exists "avatars owner manage" on storage.objects;
create policy "avatars owner manage" on storage.objects
  for all to authenticated
  using (bucket_id = 'avatars' and owner = auth.uid())
  with check (bucket_id = 'avatars' and owner = auth.uid());
