-- Transaction provenance — forward-compat seam for bank aggregation (Plaid).
--
-- v1 registers every movement manually, but we want to plug in an aggregator
-- (Plaid, in the US/CA plan) later *without* a breaking migration or duplicate
-- rows. Two columns make that a drop-in:
--
--   source       where the row came from. Defaults to 'manual' so every
--                existing and future hand-entered transaction is correct with
--                no code change.
--   external_id  the aggregator's stable transaction id (e.g. Plaid's
--                `transaction_id`). NULL for manual entries.
--
-- The partial unique index gives idempotent syncs for free: re-processing a
-- Plaid webhook upserts the same row instead of duplicating it (this also
-- closes the "idempotencia al insertar transacciones" checklist item). Manual
-- rows have a NULL external_id and are never constrained by it.

alter table public.transactions
  add column if not exists source text not null default 'manual'
    check (source in ('manual', 'plaid', 'import')),
  add column if not exists external_id text;

-- One row per (household, source, external_id) when an external id exists.
create unique index if not exists uq_tx_source_external
  on public.transactions(household_id, source, external_id)
  where external_id is not null;
