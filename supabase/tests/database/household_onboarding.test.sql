begin;

create extension if not exists pgtap with schema extensions;
set local search_path = extensions, public, auth;

select plan(11);

select has_column(
  'public',
  'households',
  'setup_completed',
  'households persist setup completion'
);

select is(
  has_function_privilege(
    'anon',
    'public.configure_household(uuid,text,text)',
    'EXECUTE'
  ),
  false,
  'anon cannot configure a household'
);

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
  ('41000000-0000-4000-8000-000000000001',
   '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'setup-owner@example.test', '', now(),
   '{"provider":"email","providers":["email"]}',
   '{"display_name":"Setup Owner"}', now(), now()),
  ('42000000-0000-4000-8000-000000000002',
   '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'other-owner@example.test', '', now(),
   '{"provider":"email","providers":["email"]}',
   '{"display_name":"Other Owner"}', now(), now());

select set_config('test.setup_household', household_id::text, true)
from public.profiles
where id = '41000000-0000-4000-8000-000000000001';

select set_config(
  'request.jwt.claim.sub',
  '41000000-0000-4000-8000-000000000001',
  true
);
select set_config(
  'request.jwt.claims',
  '{"sub":"41000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);
set local role authenticated;

select is(
  (select name || ':' || currency || ':' || setup_completed::text
   from public.configure_household(
     current_setting('test.setup_household')::uuid,
     '  Casa Norte  ',
     'cad'
   )),
  'Casa Norte:CAD:true',
  'the owner configures a normalized name and currency'
);

reset role;

select is(
  (select currency from public.profiles
   where id = '41000000-0000-4000-8000-000000000001'),
  'CAD',
  'setup aligns the owner profile currency'
);

select set_config(
  'request.jwt.claim.sub',
  '42000000-0000-4000-8000-000000000002',
  true
);
select set_config(
  'request.jwt.claims',
  '{"sub":"42000000-0000-4000-8000-000000000002","role":"authenticated"}',
  true
);
set local role authenticated;

select throws_ok(
  format(
    'select * from public.configure_household(%L, %L, %L)',
    current_setting('test.setup_household'),
    'Intruso',
    'USD'
  ),
  'P0001',
  'not_household_owner',
  'another owner cannot configure this household'
);

reset role;
select set_config(
  'request.jwt.claim.sub',
  '41000000-0000-4000-8000-000000000001',
  true
);
select set_config(
  'request.jwt.claims',
  '{"sub":"41000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);
set local role authenticated;

select throws_ok(
  format(
    'select * from public.configure_household(%L, %L, %L)',
    current_setting('test.setup_household'),
    '   ',
    'CAD'
  ),
  'P0001',
  'invalid_household_name',
  'blank household names are rejected'
);

select throws_ok(
  format(
    'select * from public.configure_household(%L, %L, %L)',
    current_setting('test.setup_household'),
    'Casa Norte',
    'dollars'
  ),
  'P0001',
  'invalid_currency',
  'non-ISO-shaped currency codes are rejected'
);

reset role;
insert into public.transactions (household_id, amount, currency, description)
values (
  current_setting('test.setup_household')::uuid,
  42,
  'CAD',
  'existing amount'
);

set local role authenticated;

select throws_ok(
  format(
    'update public.households set currency = %L where id = %L',
    'EUR',
    current_setting('test.setup_household')
  ),
  'P0001',
  'currency_change_requires_empty_household',
  'direct updates cannot bypass the currency safety rule'
);

select throws_ok(
  format(
    'select * from public.configure_household(%L, %L, %L)',
    current_setting('test.setup_household'),
    'Casa Norte',
    'EUR'
  ),
  'P0001',
  'currency_change_requires_empty_household',
  'currency cannot change once monetary data exists'
);

select is(
  (select currency from public.households
   where id = current_setting('test.setup_household')::uuid),
  'CAD',
  'a rejected currency change preserves the original currency'
);

select is(
  (select name from public.configure_household(
    current_setting('test.setup_household')::uuid,
    'Casa Norte renovada',
    'CAD'
  )),
  'Casa Norte renovada',
  'the owner can still rename a household containing data'
);

select * from finish();
rollback;
