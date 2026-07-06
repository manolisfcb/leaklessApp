-- Budget alerts — schema groundwork (Fase 5).
--
-- Adds everything the alert pipeline needs on the database side:
--
--   • budgets.alert_enabled / alert_threshold_pct — per-budget alert config.
--     The threshold is the *spent* percentage (80 = alert when 80% consumed);
--     the UI presents it as "te queda X%" (100 − threshold).
--   • budget_alert_events — one row per (budget, month, threshold) actually
--     fired. The unique constraint is the dedupe mechanism: both the local
--     watcher and the Edge Function insert with ON CONFLICT DO NOTHING and only
--     notify when the insert returned a row, so each threshold alerts once per
--     month no matter how many devices/paths race.
--   • device_push_tokens — FCM registration tokens per user, written by the
--     client (push_token_registrar.dart) and read by the budget-alert Edge
--     Function with the service-role key to push to the partner's devices.
--   • transactions.created_by — who recorded the transaction, so the Edge
--     Function can exclude that user's devices from the push (they already got
--     the in-app banner on the device that registered the expense).

-- ---------------------------------------------------------------------------
-- budgets: alert configuration
-- ---------------------------------------------------------------------------
alter table public.budgets
  add column if not exists alert_enabled boolean not null default true;
alter table public.budgets
  add column if not exists alert_threshold_pct integer not null default 80;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'budgets_alert_threshold_pct_check'
      and conrelid = 'public.budgets'::regclass
  ) then
    alter table public.budgets
      add constraint budgets_alert_threshold_pct_check
      check (alert_threshold_pct between 1 and 100);
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- budget_alert_events: dedupe ledger for fired alerts
-- ---------------------------------------------------------------------------
create table if not exists public.budget_alert_events (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  budget_id uuid not null references public.budgets(id) on delete cascade,
  period_start date not null,
  threshold_pct integer not null,
  created_at timestamptz not null default now(),
  unique (budget_id, period_start, threshold_pct)
);
create index if not exists idx_budget_alert_events_household
  on public.budget_alert_events(household_id);

alter table public.budget_alert_events enable row level security;

-- Same household-scoped policy as every other household table (init.sql).
drop policy if exists "budget_alert_events household access" on public.budget_alert_events;
create policy "budget_alert_events household access" on public.budget_alert_events
  for all to authenticated
  using (public.is_household_member(household_id))
  with check (public.is_household_member(household_id));

-- ---------------------------------------------------------------------------
-- device_push_tokens: FCM registration tokens per user
-- ---------------------------------------------------------------------------
create table if not exists public.device_push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null unique,
  platform text not null default 'unknown',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_push_tokens_user
  on public.device_push_tokens(user_id);

drop trigger if exists set_device_push_tokens_updated_at on public.device_push_tokens;
create trigger set_device_push_tokens_updated_at
  before update on public.device_push_tokens
  for each row execute function public.set_updated_at();

alter table public.device_push_tokens enable row level security;

-- Each user manages only their own tokens. The Edge Function reads the whole
-- table with the service-role key, which bypasses RLS.
drop policy if exists "push tokens self access" on public.device_push_tokens;
create policy "push tokens self access" on public.device_push_tokens
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- transactions.created_by: who recorded the expense
-- ---------------------------------------------------------------------------
-- Default auth.uid() fills it transparently on client inserts; rows created
-- before this migration (or by service-role jobs) stay NULL, which the Edge
-- Function treats as "notify everyone".
alter table public.transactions
  add column if not exists created_by uuid default auth.uid()
    references auth.users(id) on delete set null;
