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

Enable Realtime for the `transactions` table (and any others you want live) in
**Database → Replication**. The app already subscribes via
`SupabaseTransactionsRepository.watchForHousehold`.
