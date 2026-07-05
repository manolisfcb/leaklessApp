-- Keep `budgets.spent` in sync with the transactions it summarizes.
--
-- Until now `budgets.spent` was a denormalized column that nothing ever wrote,
-- so every budget rendered at 0% no matter how much the household spent. This
-- migration makes the database the single source of truth for `spent`:
--
--   • recompute_budget_spent(hh, cat, day) recalculates the `spent` of the
--     budget that owns (household, category, month-of `day`) as the sum of the
--     confirmed *expense* transactions that fall in that budget's month.
--   • an AFTER trigger on `transactions` calls it for the affected budget on
--     every INSERT / UPDATE / DELETE, passing BOTH the OLD and NEW coordinates
--     on UPDATE so a row that moves category/month/type/amount fixes up the
--     budget it left as well as the one it joined.
--
-- A budget's month is `period_start` (a `yyyy-MM-01` date written in the user's
-- local month by the app). We bucket transactions by the calendar month of
-- their `occurred_at`, using the same date_trunc on both sides so the
-- triggering row always lands in the period derived from it.
--
-- Finally we add `budgets` to the `supabase_realtime` publication so the app's
-- new budgets stream reflects these recomputed values live (same idempotent
-- pattern as 20260701000001).

-- ---------------------------------------------------------------------------
-- recompute_budget_spent
-- ---------------------------------------------------------------------------
-- SECURITY DEFINER so the recompute reads/writes household rows regardless of
-- who triggered it (e.g. an INSERT by one partner updating a shared budget).
create or replace function public.recompute_budget_spent(hh uuid, cat uuid, day date)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  period date;
begin
  -- Transactions can have a NULL category (categories.on delete set null); a
  -- budget always has one, so a NULL category means there is nothing to update.
  if hh is null or cat is null or day is null then
    return;
  end if;

  period := date_trunc('month', day)::date;

  update public.budgets b
  set spent = coalesce((
    select sum(t.amount)
    from public.transactions t
    where t.household_id = hh
      and t.category_id = cat
      and t.type = 'expense'
      and t.status = 'confirmed'
      and date_trunc('month', t.occurred_at)::date = period
  ), 0)
  where b.household_id = hh
    and b.category_id = cat
    and b.period_start = period;
end;
$$;

-- ---------------------------------------------------------------------------
-- transactions trigger → recompute the affected budget(s)
-- ---------------------------------------------------------------------------
create or replace function public.budgets_recompute_on_tx()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op in ('INSERT', 'UPDATE') then
    perform public.recompute_budget_spent(
      new.household_id, new.category_id, new.occurred_at::date);
  end if;
  if tg_op in ('UPDATE', 'DELETE') then
    perform public.recompute_budget_spent(
      old.household_id, old.category_id, old.occurred_at::date);
  end if;
  return null; -- AFTER trigger: return value is ignored.
end;
$$;

drop trigger if exists recompute_budget_spent_on_tx on public.transactions;
create trigger recompute_budget_spent_on_tx
  after insert or update or delete on public.transactions
  for each row execute function public.budgets_recompute_on_tx();

-- ---------------------------------------------------------------------------
-- Backfill existing budgets so already-recorded spending is reflected at once.
-- ---------------------------------------------------------------------------
do $$
declare b record;
begin
  for b in select household_id, category_id, period_start from public.budgets loop
    perform public.recompute_budget_spent(
      b.household_id, b.category_id, b.period_start);
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- Realtime: stream `budgets` so recomputed values reach the app live.
-- Idempotent (mirrors 20260701000001).
-- ---------------------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'budgets'
  ) then
    execute 'alter publication supabase_realtime add table public.budgets;';
  end if;
end $$;
