# Supabase — leakless

SQL migrations for the leakless backend (auth, households, transactions,
budgets, goals, subscriptions, realtime, storage).

## Apply

**Option A — SQL editor:** open each file in `migrations/` (in order) and run it
in the Supabase SQL editor.

**Option B — CLI:**

```bash
supabase link --project-ref <your-project-ref>
supabase db push
```

## Migrations

| File | Purpose |
| --- | --- |
| `20260630000001_init.sql` | Tables, indexes, `updated_at` triggers, RLS policies, avatars storage bucket. |
| `20260630000002_auto_provision_user.sql` | On sign-up, auto-create profile + starter household + owner membership + default categories. |
| `20260701000001_enable_realtime.sql` | Add the streamed tables (`transactions`, `goals`) to the `supabase_realtime` publication. |
| `20260701191145_add_household_invitations.sql` | Hashed, expiring household invitations plus create/inspect/accept/cancel RPCs. |
| `20260715213856_multicurrency_accounts_income_sources.sql` | Accounts, income sources, FX cache, immutable reporting snapshots, RLS and atomic transfer RPC. |
| `20260716005118_simplify_to_single_multicurrency_account.sql` | One internal account per household; original transaction currency stays independent from CAD reporting. |

## Daily exchange rates

`functions/sync-exchange-rates` caches the latest Bank of Canada USD/CAD
observation. Deploy it without JWT verification because it authenticates
service-to-service calls using the secret key in the `apikey` header:

```bash
supabase functions deploy sync-exchange-rates --no-verify-jwt
```

Schedule it with Supabase Cron after 17:00 Eastern and keep the project URL and
secret key in Vault. The complete SQL/runbook is in `docs/MULTIMONEDA.md`.

## Model

Everything is scoped to a **household**. RLS lets a user read/write a row only
when they are a member of that row's household, enforced by the
`public.is_household_member(uuid)` helper (SECURITY DEFINER to avoid recursive
policy evaluation on `household_members`).

The Dart enum `.name`s match the `CHECK`-constrained text columns
(`type`, `priority`, `responsible_type`, budget/goal/subscription `status`), so
`TransactionMapper` (see `lib/src/features/transactions/data/`) maps rows without
translation tables.

## Realtime

`20260701000001_enable_realtime.sql` adds the streamed tables (`transactions`,
`goals`) to the `supabase_realtime` publication — the SQL equivalent of the
**Database → Replication** toggle. Without it, `.stream()` channel joins are
accepted and then rejected with a `system` error, breaking the dashboard. Add
any new streamed table to the array in that migration.

## Auth redirect allowlist (password recovery & deep links)

The app authenticates by email/password and completes password recovery through
a custom-scheme deep link. Configure the project's **Authentication → URL
Configuration → Redirect URLs** allowlist to include:

- `leakless://app/reset-password` — target of the recovery email
  (`resetPasswordForEmail(..., redirectTo:)`, see `kPasswordRecoveryRedirect`).
- `leakless://app/invite` — invitation deep link (delivery only; authorization
  still lives in the RPCs).

Opening the recovery link establishes a short-lived recovery session; the app
pins the user to the reset-password screen (it can never reach the dashboard
before the password is changed) and calls `updateUser(password:)`. Because the
custom scheme is an opening mechanism, not an authorization one, keep the
allowlist tight and rely on Supabase's one-time recovery token for security.
Universal Links / App Links with a web fallback require a published domain and
are left to distribution configuration.

## Household invitations

Invitation operations are exposed only through the authenticated
`create_household_invitation`, `inspect_household_invitation`,
`accept_household_invitation`, and `cancel_household_invitation` RPCs. The table
has RLS enabled with no client policies, and its grants are revoked so token
hashes and invitation rows cannot be enumerated through the Data API.

Creation returns a random 256-bit token exactly once. The client must deliver
that returned secret in the invite link/QR; the database persists only its
SHA-256 digest. Do not store the plaintext token in another table or include it
in logs, analytics, or crash reports. Creating another pending invitation for
the same household/email rotates the secret and invalidates the previous one.

Acceptance verifies the authenticated user's normalized Auth email and executes
the entire membership/profile move in one transaction. It deletes the receiver's
auto-provisioned starter household only when it still matches the pristine
single-owner shape. A household with financial data, customized seed categories,
settings changes, or additional members is preserved and acceptance fails with
`current_household_not_empty`.
