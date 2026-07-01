begin;

create extension if not exists pgtap with schema extensions;
set local search_path = extensions, public, auth;

select plan(29);

select has_table(
  'public',
  'household_invitations',
  'household invitations table exists'
);

select is(
  (select relrowsecurity from pg_class
   where oid = 'public.household_invitations'::regclass),
  true,
  'household invitations has RLS enabled'
);

select is(
  has_function_privilege(
    'anon',
    'public.create_household_invitation(uuid,text,interval)',
    'EXECUTE'
  ),
  false,
  'anon cannot execute invitation creation'
);

select is(
  has_function_privilege(
    'authenticated',
    'public.accept_household_invitation(text)',
    'EXECUTE'
  ),
  true,
  'authenticated users can execute invitation acceptance'
);

-- The production auth trigger provisions a starter household for every user.
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
  ('31000000-0000-4000-8000-000000000001',
   '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'owner-a@example.test', '', now(),
   '{"provider":"email","providers":["email"]}',
   '{"display_name":"Owner A"}', now(), now()),
  ('32000000-0000-4000-8000-000000000002',
   '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'recipient-b@example.test', '', now(),
   '{"provider":"email","providers":["email"]}',
   '{"display_name":"Recipient B"}', now(), now()),
  ('33000000-0000-4000-8000-000000000003',
   '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'owner-d@example.test', '', now(),
   '{"provider":"email","providers":["email"]}',
   '{"display_name":"Owner D"}', now(), now()),
  ('34000000-0000-4000-8000-000000000004',
   '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'recipient-e@example.test', '', now(),
   '{"provider":"email","providers":["email"]}',
   '{"display_name":"Recipient E"}', now(), now()),
  ('35000000-0000-4000-8000-000000000005',
   '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'owner-g@example.test', '', now(),
   '{"provider":"email","providers":["email"]}',
   '{"display_name":"Owner G"}', now(), now()),
  ('36000000-0000-4000-8000-000000000006',
   '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'recipient-f@example.test', '', now(),
   '{"provider":"email","providers":["email"]}',
   '{"display_name":"Recipient F"}', now(), now()),
  ('37000000-0000-4000-8000-000000000007',
   '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'recipient-i@example.test', '', now(),
   '{"provider":"email","providers":["email"]}',
   '{"display_name":"Recipient I"}', now(), now()),
  ('38000000-0000-4000-8000-000000000008',
   '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'extra-j@example.test', '', now(),
   '{"provider":"email","providers":["email"]}',
   '{"display_name":"Extra J"}', now(), now()),
  ('39000000-0000-4000-8000-000000000009',
   '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'outsider-c@example.test', '', now(),
   '{"provider":"email","providers":["email"]}',
   '{"display_name":"Outsider C"}', now(), now());

select set_config('test.household_a', household_id::text, true)
from public.profiles where id = '31000000-0000-4000-8000-000000000001';
select set_config('test.household_b', household_id::text, true)
from public.profiles where id = '32000000-0000-4000-8000-000000000002';
select set_config('test.household_d', household_id::text, true)
from public.profiles where id = '33000000-0000-4000-8000-000000000003';
select set_config('test.household_e', household_id::text, true)
from public.profiles where id = '34000000-0000-4000-8000-000000000004';
select set_config('test.household_g', household_id::text, true)
from public.profiles where id = '35000000-0000-4000-8000-000000000005';
select set_config('test.household_f', household_id::text, true)
from public.profiles where id = '36000000-0000-4000-8000-000000000006';
select set_config('test.household_i', household_id::text, true)
from public.profiles where id = '37000000-0000-4000-8000-000000000007';

-- Owner A creates an invitation. Mixed-case/whitespace input verifies that
-- only the normalized email is persisted. The plaintext secret is captured
-- from the one-time RPC response for subsequent calls.
select set_config(
  'request.jwt.claim.sub',
  '31000000-0000-4000-8000-000000000001',
  true
);
select set_config(
  'request.jwt.claims',
  '{"sub":"31000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);
set local role authenticated;

select
  set_config('test.invitation_a', invitation_id::text, true),
  set_config('test.token_a', token, true)
from public.create_household_invitation(
  current_setting('test.household_a')::uuid,
  '  Recipient-B@Example.Test  '
);

reset role;

select is(
  (select invited_email from public.household_invitations
   where id = current_setting('test.invitation_a')::uuid),
  'recipient-b@example.test',
  'creation normalizes the invited email'
);

select isnt(
  (select encode(token_hash, 'hex') from public.household_invitations
   where id = current_setting('test.invitation_a')::uuid),
  encode(convert_to(current_setting('test.token_a'), 'UTF8'), 'hex'),
  'the plaintext invitation token is never stored'
);

select is(
  (select token_hash from public.household_invitations
   where id = current_setting('test.invitation_a')::uuid),
  extensions.digest(current_setting('test.token_a'), 'sha256'),
  'the persisted token value is a SHA-256 digest'
);

-- Only the matching authenticated email can inspect or accept the token.
select set_config(
  'request.jwt.claim.sub',
  '32000000-0000-4000-8000-000000000002',
  true
);
select set_config(
  'request.jwt.claims',
  '{"sub":"32000000-0000-4000-8000-000000000002","role":"authenticated"}',
  true
);
set local role authenticated;

select is(
  (select household_id::text || ':' || status
   from public.inspect_household_invitation(current_setting('test.token_a'))),
  current_setting('test.household_a') || ':pending',
  'the intended recipient can inspect a pending invitation'
);

reset role;
select set_config(
  'request.jwt.claim.sub',
  '39000000-0000-4000-8000-000000000009',
  true
);
select set_config(
  'request.jwt.claims',
  '{"sub":"39000000-0000-4000-8000-000000000009","role":"authenticated"}',
  true
);
set local role authenticated;

select throws_ok(
  $test$select * from public.inspect_household_invitation(
    current_setting('test.token_a'))$test$,
  'P0001',
  'invitation_email_mismatch',
  'a different email cannot inspect the invitation'
);

select throws_ok(
  $test$select * from public.accept_household_invitation(
    current_setting('test.token_a'))$test$,
  'P0001',
  'invitation_email_mismatch',
  'a different email cannot accept the invitation'
);

reset role;
select set_config(
  'request.jwt.claim.sub',
  '32000000-0000-4000-8000-000000000002',
  true
);
select set_config(
  'request.jwt.claims',
  '{"sub":"32000000-0000-4000-8000-000000000002","role":"authenticated"}',
  true
);
set local role authenticated;

select is(
  (select status || ':' || already_accepted::text
   from public.accept_household_invitation(current_setting('test.token_a'))),
  'accepted:false',
  'the recipient accepts a valid invitation'
);

reset role;

select is(
  (select household_id from public.profiles
   where id = '32000000-0000-4000-8000-000000000002'),
  current_setting('test.household_a')::uuid,
  'acceptance points the recipient profile at the shared household'
);

select is(
  (select role from public.household_members
   where household_id = current_setting('test.household_a')::uuid
     and user_id = '32000000-0000-4000-8000-000000000002'),
  'member',
  'acceptance creates the recipient member row'
);

select is(
  (select count(*) from public.households
   where id = current_setting('test.household_b')::uuid),
  0::bigint,
  'acceptance deletes the empty auto-provisioned household'
);

select set_config(
  'request.jwt.claim.sub',
  '32000000-0000-4000-8000-000000000002',
  true
);
select set_config(
  'request.jwt.claims',
  '{"sub":"32000000-0000-4000-8000-000000000002","role":"authenticated"}',
  true
);
set local role authenticated;

select is(
  (select already_accepted
   from public.accept_household_invitation(current_setting('test.token_a'))),
  true,
  'reusing an accepted token by the same recipient is idempotent'
);

select throws_ok(
  $test$select * from public.accept_household_invitation('not-a-token')$test$,
  'P0001',
  'invalid_invitation_token',
  'an invalid token is rejected'
);

select throws_ok(
  format(
    'insert into public.household_members (household_id, user_id) '
    'values (%L, %L)',
    current_setting('test.household_a'),
    '39000000-0000-4000-8000-000000000009'
  ),
  '42501',
  null,
  'a user cannot bypass invitations with a direct member insert'
);

select throws_ok(
  'select * from public.household_invitations',
  '42501',
  null,
  'authenticated users cannot enumerate invitation rows or hashes'
);

-- Owner D creates an invitation for E. An unrelated owner cannot cancel it;
-- the owning household can cancel it, and a cancelled secret cannot be used.
reset role;
select set_config(
  'request.jwt.claim.sub',
  '33000000-0000-4000-8000-000000000003',
  true
);
select set_config(
  'request.jwt.claims',
  '{"sub":"33000000-0000-4000-8000-000000000003","role":"authenticated"}',
  true
);
set local role authenticated;

select
  set_config('test.invitation_d', invitation_id::text, true),
  set_config('test.token_d', token, true)
from public.create_household_invitation(
  current_setting('test.household_d')::uuid,
  'recipient-e@example.test'
);

reset role;
select set_config(
  'request.jwt.claim.sub',
  '31000000-0000-4000-8000-000000000001',
  true
);
select set_config(
  'request.jwt.claims',
  '{"sub":"31000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);
set local role authenticated;

select throws_ok(
  $test$select * from public.cancel_household_invitation(
    current_setting('test.invitation_d')::uuid)$test$,
  'P0001',
  'not_household_owner',
  'an owner cannot cancel an invitation from another household'
);

reset role;
select set_config(
  'request.jwt.claim.sub',
  '34000000-0000-4000-8000-000000000004',
  true
);
select set_config(
  'request.jwt.claims',
  '{"sub":"34000000-0000-4000-8000-000000000004","role":"authenticated"}',
  true
);
set local role authenticated;

select throws_ok(
  format(
    'select * from public.create_household_invitation(%L, %L)',
    current_setting('test.household_d'),
    'outsider-c@example.test'
  ),
  'P0001',
  'not_household_owner',
  'a non-owner cannot create an invitation'
);

reset role;
select set_config(
  'request.jwt.claim.sub',
  '33000000-0000-4000-8000-000000000003',
  true
);
select set_config(
  'request.jwt.claims',
  '{"sub":"33000000-0000-4000-8000-000000000003","role":"authenticated"}',
  true
);
set local role authenticated;

select is(
  (select status from public.cancel_household_invitation(
    current_setting('test.invitation_d')::uuid)),
  'cancelled',
  'the household owner can cancel a pending invitation'
);

reset role;
select set_config(
  'request.jwt.claim.sub',
  '34000000-0000-4000-8000-000000000004',
  true
);
select set_config(
  'request.jwt.claims',
  '{"sub":"34000000-0000-4000-8000-000000000004","role":"authenticated"}',
  true
);
set local role authenticated;

select throws_ok(
  $test$select * from public.accept_household_invitation(
    current_setting('test.token_d'))$test$,
  'P0001',
  'invitation_cancelled',
  'a cancelled invitation cannot be accepted'
);

-- Recreate D -> E, then age it as a database fixture. Inspection reports the
-- derived expired state and acceptance rejects it.
reset role;
select set_config(
  'request.jwt.claim.sub',
  '33000000-0000-4000-8000-000000000003',
  true
);
select set_config(
  'request.jwt.claims',
  '{"sub":"33000000-0000-4000-8000-000000000003","role":"authenticated"}',
  true
);
set local role authenticated;

select
  set_config('test.invitation_expired', invitation_id::text, true),
  set_config('test.token_expired', token, true)
from public.create_household_invitation(
  current_setting('test.household_d')::uuid,
  'recipient-e@example.test'
);

reset role;
update public.household_invitations
set created_at = now() - interval '2 days',
    expires_at = now() - interval '1 day'
where id = current_setting('test.invitation_expired')::uuid;

select set_config(
  'request.jwt.claim.sub',
  '34000000-0000-4000-8000-000000000004',
  true
);
select set_config(
  'request.jwt.claims',
  '{"sub":"34000000-0000-4000-8000-000000000004","role":"authenticated"}',
  true
);
set local role authenticated;

select is(
  (select status from public.inspect_household_invitation(
    current_setting('test.token_expired'))),
  'expired',
  'inspection reports an expired pending invitation'
);

select throws_ok(
  $test$select * from public.accept_household_invitation(
    current_setting('test.token_expired'))$test$,
  'P0001',
  'invitation_expired',
  'an expired invitation cannot be accepted'
);

-- A starter household with financial data must survive a failed acceptance.
reset role;
select set_config(
  'request.jwt.claim.sub',
  '35000000-0000-4000-8000-000000000005',
  true
);
select set_config(
  'request.jwt.claims',
  '{"sub":"35000000-0000-4000-8000-000000000005","role":"authenticated"}',
  true
);
set local role authenticated;

select set_config('test.token_f', token, true)
from public.create_household_invitation(
  current_setting('test.household_g')::uuid,
  'recipient-f@example.test'
);

reset role;
insert into public.transactions (household_id, amount, description)
values (current_setting('test.household_f')::uuid, 42, 'must survive');

select set_config(
  'request.jwt.claim.sub',
  '36000000-0000-4000-8000-000000000006',
  true
);
select set_config(
  'request.jwt.claims',
  '{"sub":"36000000-0000-4000-8000-000000000006","role":"authenticated"}',
  true
);
set local role authenticated;

select throws_ok(
  $test$select * from public.accept_household_invitation(
    current_setting('test.token_f'))$test$,
  'P0001',
  'current_household_not_empty',
  'acceptance refuses to delete a starter household containing data'
);

reset role;
select is(
  (select count(*) from public.transactions
   where household_id = current_setting('test.household_f')::uuid),
  1::bigint,
  'failed acceptance preserves the existing household data'
);

select is(
  (select status from public.household_invitations
   where token_hash = extensions.digest(current_setting('test.token_f'), 'sha256')),
  'pending',
  'failed acceptance leaves the invitation pending atomically'
);

-- A starter household with more than one member must also survive untouched.
select set_config(
  'request.jwt.claim.sub',
  '35000000-0000-4000-8000-000000000005',
  true
);
select set_config(
  'request.jwt.claims',
  '{"sub":"35000000-0000-4000-8000-000000000005","role":"authenticated"}',
  true
);
set local role authenticated;

select set_config('test.token_i', token, true)
from public.create_household_invitation(
  current_setting('test.household_g')::uuid,
  'recipient-i@example.test'
);

reset role;
insert into public.household_members (
  household_id,
  user_id,
  display_name,
  role
)
values (
  current_setting('test.household_i')::uuid,
  '38000000-0000-4000-8000-000000000008',
  'Extra J',
  'member'
);

select set_config(
  'request.jwt.claim.sub',
  '37000000-0000-4000-8000-000000000007',
  true
);
select set_config(
  'request.jwt.claims',
  '{"sub":"37000000-0000-4000-8000-000000000007","role":"authenticated"}',
  true
);
set local role authenticated;

select throws_ok(
  $test$select * from public.accept_household_invitation(
    current_setting('test.token_i'))$test$,
  'P0001',
  'current_household_not_empty',
  'acceptance refuses to delete a starter household with multiple members'
);

reset role;
select is(
  (select count(*) from public.household_members
   where household_id = current_setting('test.household_i')::uuid),
  2::bigint,
  'failed acceptance preserves every existing starter-household member'
);

select * from finish();
rollback;
