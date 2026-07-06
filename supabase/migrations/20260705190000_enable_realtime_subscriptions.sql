-- leakless — enable Realtime replication for the `subscriptions` table.
--
-- SupabaseSubscriptionsRepository streams the household's recurring charges via
-- `.stream()`, but `subscriptions` was never added to the `supabase_realtime`
-- publication (only `transactions`/`goals` in 20260701000001 and `budgets` in
-- 20260705000001 were). Without it Realtime accepts the channel join and then
-- immediately rejects it with a `system` error, the stream errors out, and the
-- subscriptions list fails to load live updates.
--
-- Idempotent: safe to re-run.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'subscriptions'
  ) then
    execute 'alter publication supabase_realtime add table public.subscriptions;';
  end if;
end $$;
