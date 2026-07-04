begin;

create extension if not exists pgtap with schema extensions;
set local search_path = extensions, public, auth;

select plan(21);

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------
select has_function('public', 'delete_account', array['boolean'],
  'delete_account(boolean) exists');

select is(
  has_function_privilege('anon', 'public.delete_account(boolean)', 'EXECUTE'),
  false,
  'anon cannot execute delete_account'
);

select is(
  has_function_privilege(
    'authenticated', 'public.delete_account(boolean)', 'EXECUTE'
  ),
  true,
  'authenticated users can execute delete_account'
);

-- ---------------------------------------------------------------------------
-- Users (each gets a starter household from the auth trigger)
-- ---------------------------------------------------------------------------
insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at
)
values
  ('41000000-0000-4000-8000-000000000001',
   '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'owner-shared@example.test', '', now(),
   '{"provider":"email","providers":["email"]}',
   '{"display_name":"Owner Shared"}', now(), now()),
  ('42000000-0000-4000-8000-000000000002',
   '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'partner@example.test', '', now(),
   '{"provider":"email","providers":["email"]}',
   '{"display_name":"Partner"}', now(), now()),
  ('43000000-0000-4000-8000-000000000003',
   '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'solo@example.test', '', now(),
   '{"provider":"email","providers":["email"]}',
   '{"display_name":"Solo"}', now(), now()),
  ('45000000-0000-4000-8000-000000000005',
   '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'owner-d@example.test', '', now(),
   '{"provider":"email","providers":["email"]}',
   '{"display_name":"Owner D"}', now(), now()),
  ('46000000-0000-4000-8000-000000000006',
   '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'leaving-member@example.test', '', now(),
   '{"provider":"email","providers":["email"]}',
   '{"display_name":"Leaving Member"}', now(), now());

-- Capture the starter households.
select set_config('test.h1', household_id::text, true)
from public.profiles where id = '41000000-0000-4000-8000-000000000001';
select set_config('test.h_partner_starter', household_id::text, true)
from public.profiles where id = '42000000-0000-4000-8000-000000000002';
select set_config('test.h3', household_id::text, true)
from public.profiles where id = '43000000-0000-4000-8000-000000000003';
select set_config('test.hd', household_id::text, true)
from public.profiles where id = '45000000-0000-4000-8000-000000000005';
select set_config('test.h_member_starter', household_id::text, true)
from public.profiles where id = '46000000-0000-4000-8000-000000000006';

-- Build a *shared* household H1: drop the partner's starter and move them into
-- Owner Shared's household as a member, with a transaction to prove survival.
delete from public.households
where id = current_setting('test.h_partner_starter')::uuid;
insert into public.household_members (household_id, user_id, display_name, role)
values (
  current_setting('test.h1')::uuid,
  '42000000-0000-4000-8000-000000000002',
  'Partner', 'member'
);
update public.profiles
set household_id = current_setting('test.h1')::uuid
where id = '42000000-0000-4000-8000-000000000002';
insert into public.transactions (household_id, amount)
values (current_setting('test.h1')::uuid, 42.00);

-- An avatar object owned by the leaving owner (cleaned up on deletion).
insert into storage.objects (bucket_id, name, owner)
values (
  'avatars',
  '41000000-0000-4000-8000-000000000001/avatar.jpg',
  '41000000-0000-4000-8000-000000000001'
);

-- Build a *shared* household Hd: move the leaving member into Owner D's
-- household as a non-owner member.
delete from public.households
where id = current_setting('test.h_member_starter')::uuid;
insert into public.household_members (household_id, user_id, display_name, role)
values (
  current_setting('test.hd')::uuid,
  '46000000-0000-4000-8000-000000000006',
  'Leaving Member', 'member'
);
update public.profiles
set household_id = current_setting('test.hd')::uuid
where id = '46000000-0000-4000-8000-000000000006';

-- ---------------------------------------------------------------------------
-- Scenario A — a shared-household owner deletes: ownership transfers, shared
-- data is preserved, only the leaving owner's own rows disappear.
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claim.sub',
  '41000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claims',
  '{"sub":"41000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
set local role authenticated;

select lives_ok(
  $test$select public.delete_account(false)$test$,
  'shared-household owner can delete their account'
);

reset role;

select is(
  (select count(*) from public.households
   where id = current_setting('test.h1')::uuid),
  1::bigint,
  'shared household is preserved after the owner leaves'
);
select is(
  (select owner_id from public.households
   where id = current_setting('test.h1')::uuid),
  '42000000-0000-4000-8000-000000000002'::uuid,
  'ownership transferred to the remaining member'
);
select is(
  (select role from public.household_members
   where household_id = current_setting('test.h1')::uuid
     and user_id = '42000000-0000-4000-8000-000000000002'),
  'owner',
  'the remaining member is promoted to owner'
);
select is(
  (select count(*) from public.household_members
   where user_id = '41000000-0000-4000-8000-000000000001'),
  0::bigint,
  'the leaving owner membership is removed'
);
select is(
  (select count(*) from public.profiles
   where id = '41000000-0000-4000-8000-000000000001'),
  0::bigint,
  'the leaving owner profile is removed'
);
select is(
  (select count(*) from auth.users
   where id = '41000000-0000-4000-8000-000000000001'),
  0::bigint,
  'the leaving owner auth user is removed'
);
select is(
  (select count(*) from public.transactions
   where household_id = current_setting('test.h1')::uuid),
  1::bigint,
  'the partner''s shared transaction survives'
);
select is(
  (select count(*) from storage.objects
   where bucket_id = 'avatars'
     and (storage.foldername(name))[1]
       = '41000000-0000-4000-8000-000000000001'),
  0::bigint,
  'the leaving owner''s avatar objects are cleaned up'
);

-- ---------------------------------------------------------------------------
-- Scenario B — a solo member without confirmation is rejected, nothing lost.
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claim.sub',
  '43000000-0000-4000-8000-000000000003', true);
select set_config('request.jwt.claims',
  '{"sub":"43000000-0000-4000-8000-000000000003","role":"authenticated"}', true);
set local role authenticated;

select throws_ok(
  $test$select public.delete_account(false)$test$,
  'P0001',
  'household_deletion_not_confirmed',
  'solo deletion without confirmation is rejected'
);

reset role;

select is(
  (select count(*) from auth.users
   where id = '43000000-0000-4000-8000-000000000003'),
  1::bigint,
  'a rejected solo deletion leaves the account intact'
);
select is(
  (select count(*) from public.households
   where id = current_setting('test.h3')::uuid),
  1::bigint,
  'a rejected solo deletion leaves the household intact'
);

-- ---------------------------------------------------------------------------
-- Scenario C — a solo member with confirmation deletes household + data.
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claim.sub',
  '43000000-0000-4000-8000-000000000003', true);
select set_config('request.jwt.claims',
  '{"sub":"43000000-0000-4000-8000-000000000003","role":"authenticated"}', true);
set local role authenticated;

select lives_ok(
  $test$select public.delete_account(true)$test$,
  'solo deletion with confirmation succeeds'
);

reset role;

select is(
  (select count(*) from public.households
   where id = current_setting('test.h3')::uuid),
  0::bigint,
  'the confirmed solo household is deleted'
);
select is(
  (select count(*) from auth.users
   where id = '43000000-0000-4000-8000-000000000003'),
  0::bigint,
  'the confirmed solo account is deleted'
);

-- ---------------------------------------------------------------------------
-- Scenario D — a non-owner member leaves; the household and owner survive.
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claim.sub',
  '46000000-0000-4000-8000-000000000006', true);
select set_config('request.jwt.claims',
  '{"sub":"46000000-0000-4000-8000-000000000006","role":"authenticated"}', true);
set local role authenticated;

select lives_ok(
  $test$select public.delete_account(false)$test$,
  'a non-owner member can delete their account without confirmation'
);

reset role;

select is(
  (select owner_id from public.households
   where id = current_setting('test.hd')::uuid),
  '45000000-0000-4000-8000-000000000005'::uuid,
  'the household keeps its original owner when a member leaves'
);
select is(
  (select count(*) from public.household_members
   where user_id = '46000000-0000-4000-8000-000000000006'),
  0::bigint,
  'the leaving member membership is removed'
);

select * from finish();
rollback;
