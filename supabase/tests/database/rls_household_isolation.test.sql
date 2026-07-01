begin;

create extension if not exists pgtap with schema extensions;
set local search_path = extensions, public, auth;

select plan(21);

-- Fixed fixture users make failures reproducible. The production
-- `on_auth_user_created` trigger provisions one isolated household per user.
insert into auth.users (
  id,
  instance_id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
values
  (
    '11111111-1111-4111-8111-111111111111',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'rls-household-a@example.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"display_name":"RLS Household A"}',
    now(),
    now()
  ),
  (
    '22222222-2222-4222-8222-222222222222',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'rls-household-b@example.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"display_name":"RLS Household B"}',
    now(),
    now()
  );

select set_config(
  'test.household_a',
  (select household_id::text from public.profiles
   where id = '11111111-1111-4111-8111-111111111111'),
  true
);
select set_config(
  'test.household_b',
  (select household_id::text from public.profiles
   where id = '22222222-2222-4222-8222-222222222222'),
  true
);

select isnt(
  current_setting('test.household_a'),
  current_setting('test.household_b'),
  'the auth trigger provisions two distinct households'
);

-- One row per household in every financial table protected by the shared
-- `is_household_member(household_id)` policy. Categories are already seeded by
-- the production trigger and are reused by the budget fixtures.
insert into public.transactions (household_id, amount, description)
values
  (current_setting('test.household_a')::uuid, 10, 'fixture A'),
  (current_setting('test.household_b')::uuid, 20, 'fixture B');

insert into public.budgets (
  household_id,
  category_id,
  amount_limit,
  period_start
)
select
  household_id,
  (array_agg(id order by id))[1],
  100,
  date '2026-07-01'
from public.categories
where household_id in (
  current_setting('test.household_a')::uuid,
  current_setting('test.household_b')::uuid
)
group by household_id;

insert into public.goals (household_id, name, target_amount)
values
  (current_setting('test.household_a')::uuid, 'Goal A', 1000),
  (current_setting('test.household_b')::uuid, 'Goal B', 2000);

insert into public.subscriptions (household_id, name, amount)
values
  (current_setting('test.household_a')::uuid, 'Subscription A', 5),
  (current_setting('test.household_b')::uuid, 'Subscription B', 6);

insert into public.notification_events (household_id, type, title, body)
values
  (current_setting('test.household_a')::uuid, 'test', 'Notice A', 'fixture A'),
  (current_setting('test.household_b')::uuid, 'test', 'Notice B', 'fixture B');

-- Authenticate as household A. These queries run as the same Postgres role and
-- auth.uid() shape used by the Data API, so RLS is exercised rather than
-- emulated.
select set_config(
  'request.jwt.claim.sub',
  '11111111-1111-4111-8111-111111111111',
  true
);
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}',
  true
);
set local role authenticated;

select is((select count(*) = 1 and bool_and(id =
  '11111111-1111-4111-8111-111111111111') from public.profiles), true,
  'A reads only its own profile');
select is((select count(*) = 1 and bool_and(id =
  current_setting('test.household_a')::uuid) from public.households), true,
  'A reads only its household');
select is((select count(*) = 1 and bool_and(household_id =
  current_setting('test.household_a')::uuid) from public.household_members), true,
  'A reads only members of its household');
select is((select count(*) = 6 and bool_and(household_id =
  current_setting('test.household_a')::uuid) from public.categories), true,
  'A reads only its six seeded categories');
select is((select count(*) = 1 and bool_and(household_id =
  current_setting('test.household_a')::uuid) from public.transactions), true,
  'A cannot read B transactions');
select is((select count(*) = 1 and bool_and(household_id =
  current_setting('test.household_a')::uuid) from public.budgets), true,
  'A cannot read B budgets');
select is((select count(*) = 1 and bool_and(household_id =
  current_setting('test.household_a')::uuid) from public.goals), true,
  'A cannot read B goals');
select is((select count(*) = 1 and bool_and(household_id =
  current_setting('test.household_a')::uuid) from public.subscriptions), true,
  'A cannot read B subscriptions');
select is((select count(*) = 1 and bool_and(household_id =
  current_setting('test.household_a')::uuid) from public.notification_events), true,
  'A cannot read B notifications');
select throws_ok(
  $$
    insert into public.transactions (household_id, amount, description)
    values (current_setting('test.household_b')::uuid, 99, 'cross-household')
  $$,
  '42501',
  null,
  'A cannot insert a transaction into B household'
);

-- Repeat from the opposite side so the test cannot pass because one fixture or
-- one user was accidentally privileged.
reset role;
select set_config(
  'request.jwt.claim.sub',
  '22222222-2222-4222-8222-222222222222',
  true
);
select set_config(
  'request.jwt.claims',
  '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated"}',
  true
);
set local role authenticated;

select is((select count(*) = 1 and bool_and(id =
  '22222222-2222-4222-8222-222222222222') from public.profiles), true,
  'B reads only its own profile');
select is((select count(*) = 1 and bool_and(id =
  current_setting('test.household_b')::uuid) from public.households), true,
  'B reads only its household');
select is((select count(*) = 1 and bool_and(household_id =
  current_setting('test.household_b')::uuid) from public.household_members), true,
  'B reads only members of its household');
select is((select count(*) = 6 and bool_and(household_id =
  current_setting('test.household_b')::uuid) from public.categories), true,
  'B reads only its six seeded categories');
select is((select count(*) = 1 and bool_and(household_id =
  current_setting('test.household_b')::uuid) from public.transactions), true,
  'B cannot read A transactions');
select is((select count(*) = 1 and bool_and(household_id =
  current_setting('test.household_b')::uuid) from public.budgets), true,
  'B cannot read A budgets');
select is((select count(*) = 1 and bool_and(household_id =
  current_setting('test.household_b')::uuid) from public.goals), true,
  'B cannot read A goals');
select is((select count(*) = 1 and bool_and(household_id =
  current_setting('test.household_b')::uuid) from public.subscriptions), true,
  'B cannot read A subscriptions');
select is((select count(*) = 1 and bool_and(household_id =
  current_setting('test.household_b')::uuid) from public.notification_events), true,
  'B cannot read A notifications');
select throws_ok(
  $$
    insert into public.transactions (household_id, amount, description)
    values (current_setting('test.household_a')::uuid, 99, 'cross-household')
  $$,
  '42501',
  null,
  'B cannot insert a transaction into A household'
);

reset role;
select * from finish();
rollback;
