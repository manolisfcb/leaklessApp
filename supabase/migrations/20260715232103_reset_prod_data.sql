-- ONE-OFF data wipe (2026-07-15): empezar de cero conservando cuentas.
-- Queda en el historial como registro de la limpieza aplicada a prod.
-- Re-ejecutarla sobre una base vacía es un no-op (truncates sin filas y
-- seeds que dependen de households existentes), así que es replay-safe.
--
-- Borra el contenido financiero; conserva auth.users, profiles, households,
-- household_members, device_push_tokens y exchange_rates. Re-siembra las 10
-- categorías por defecto y una "Cuenta principal" por hogar, igual que el
-- backfill de 20260715213856_multicurrency_accounts_income_sources.sql.

truncate table
  public.transactions,
  public.subscriptions,
  public.budget_alert_events,
  public.budgets,
  public.goals,
  public.income_sources,
  public.accounts,
  public.notification_events,
  public.household_invitations,
  public.categories;

insert into public.categories (household_id, name, icon_name, is_default, slug)
select h.id, c.name, c.icon_name, true, c.slug
from public.households h
cross join (values
  ('Supermercado', 'cart', 'groceries'),
  ('Restaurantes', 'restaurant', 'dining'),
  ('Transporte', 'car', 'transport'),
  ('Ocio', 'movie', 'leisure'),
  ('Suscripciones', 'subscriptions', 'subscriptions'),
  ('Ahorro', 'savings', 'savings'),
  ('Gastos esenciales', 'essentials', 'essentials'),
  ('Estudios', 'education', 'education'),
  ('Reserva de emergencia', 'emergency', 'emergency_fund'),
  ('Salud', 'health', 'health')
) as c(name, icon_name, slug);

insert into public.accounts (
  household_id, name, currency, kind, opening_balance, opening_balance_at,
  icon_name, is_default
)
select h.id, 'Cuenta principal', h.currency, 'checking', 0, now(), 'bank', true
from public.households h;
