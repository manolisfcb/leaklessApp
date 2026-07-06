-- Subscription reminders — recurring-expense scheduling groundwork (Fase 6).
--
-- Extends public.subscriptions so a recurring charge can drive an on-device
-- local reminder (no Firebase involved — the client schedules the notification
-- itself; see local_reminder_scheduler.dart):
--
--   • frequency          — how often the charge repeats. The client advances
--                          next_charge_at by this cadence when a date passes,
--                          keeping reminders firing across months.
--   • reminder_enabled    — whether to schedule a local notification at all.
--   • reminder_days_before — how many days before next_charge_at to fire it
--                            (0 = on the charge day itself; capped at 30).

alter table public.subscriptions
  add column if not exists frequency text not null default 'monthly';

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'subscriptions_frequency_check'
      and conrelid = 'public.subscriptions'::regclass
  ) then
    alter table public.subscriptions
      add constraint subscriptions_frequency_check
      check (frequency in ('weekly', 'monthly', 'yearly'));
  end if;
end $$;

alter table public.subscriptions
  add column if not exists reminder_enabled boolean not null default false;

alter table public.subscriptions
  add column if not exists reminder_days_before integer not null default 1;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'subscriptions_reminder_days_before_check'
      and conrelid = 'public.subscriptions'::regclass
  ) then
    alter table public.subscriptions
      add constraint subscriptions_reminder_days_before_check
      check (reminder_days_before between 0 and 30);
  end if;
end $$;
