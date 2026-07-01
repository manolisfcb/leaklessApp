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
