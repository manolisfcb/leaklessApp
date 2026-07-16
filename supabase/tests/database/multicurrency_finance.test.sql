begin;

create extension if not exists pgtap with schema extensions;
set local search_path = extensions, public, auth;
select plan(12);

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
('71000000-0000-4000-8000-000000000001', '00000000-0000-0000-0000-000000000000',
 'authenticated', 'authenticated', 'fx-a@example.test', '', now(),
 '{"provider":"email","providers":["email"]}', '{"display_name":"FX A"}', now(), now()),
('72000000-0000-4000-8000-000000000002', '00000000-0000-0000-0000-000000000000',
 'authenticated', 'authenticated', 'fx-b@example.test', '', now(),
 '{"provider":"email","providers":["email"]}', '{"display_name":"FX B"}', now(), now());

select set_config('test.fx_household_a', household_id::text, true)
from public.profiles where id = '71000000-0000-4000-8000-000000000001';
select set_config('test.fx_household_b', household_id::text, true)
from public.profiles where id = '72000000-0000-4000-8000-000000000002';

select is((select count(*) from public.accounts where household_id = current_setting('test.fx_household_a')::uuid), 1::bigint,
  'a default account is provisioned');

update public.households set currency = 'CAD'
where id in (current_setting('test.fx_household_a')::uuid, current_setting('test.fx_household_b')::uuid);

select is((select currency from public.accounts where household_id = current_setting('test.fx_household_a')::uuid), 'CAD',
  'an empty default account follows the reporting currency');

select set_config('test.fx_cad_account', id::text, true) from public.accounts
where household_id = current_setting('test.fx_household_a')::uuid and currency = 'CAD';

insert into public.exchange_rates (
  rate_date, foreign_currency, reporting_currency, rate, source, raw_observation_date
) values (date '2026-07-15', 'USD', 'CAD', 1.37, 'bank_of_canada', date '2026-07-15');

select set_config('request.jwt.claim.sub', '71000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claims', '{"sub":"71000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
set local role authenticated;

select is((select count(*) from public.accounts), 1::bigint, 'RLS exposes only household A account');
select is((select count(*) from public.exchange_rates), 1::bigint, 'authenticated users can read rates');
select throws_ok(
  format(
    'insert into public.accounts (household_id, name, currency) values (%L,%L,%L)',
    current_setting('test.fx_household_a'), 'Otra cuenta', 'USD'
  ),
  '23505', null, 'a household cannot create a second active account');
select throws_ok(
  $$insert into public.exchange_rates (rate_date, foreign_currency, reporting_currency, rate, source, raw_observation_date)
    values (date '2026-07-16', 'USD', 'CAD', 1.38, 'client', date '2026-07-16')$$,
  '42501', null, 'clients cannot write exchange rates');

insert into public.income_sources (
  household_id, name, default_currency, default_account_id
) values (
  current_setting('test.fx_household_a')::uuid, 'Mi app', 'USD',
  current_setting('test.fx_cad_account')::uuid
);
select is((select count(*) from public.income_sources), 1::bigint, 'a member creates an income source');
select throws_ok(
  $$insert into public.income_sources (household_id, name, default_currency)
    values (current_setting('test.fx_household_a')::uuid, '  MI APP  ', 'USD')$$,
  '23505', null, 'active source names are unique ignoring case and spaces');

select lives_ok(
  $$insert into public.transactions (
      household_id, account_id, amount, currency, type,
      reporting_currency, exchange_rate_to_reporting, exchange_rate_date,
      exchange_rate_source, amount_reporting
    ) values (
      current_setting('test.fx_household_a')::uuid,
      current_setting('test.fx_cad_account')::uuid,
      10, 'USD', 'expense', 'CAD', 1.37, date '2026-07-15', 'test', 13.70
    )$$,
  'one account accepts a transaction in a different original currency');
select is(
  (select amount_reporting from public.transactions where currency = 'USD'),
  13.70::numeric,
  'the cross-currency transaction keeps its CAD reporting snapshot'
);

select lives_ok(
  $$insert into public.transactions (household_id, amount, currency, description)
    values (current_setting('test.fx_household_a')::uuid, 10, 'CAD', 'legacy write')$$,
  'same-currency legacy writes receive safe defaults');
select is((select amount_reporting from public.transactions where description = 'legacy write'), 10.00::numeric,
  'legacy write gets an identity reporting snapshot');

reset role;
select * from finish();
rollback;
