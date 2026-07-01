-- leakless — enable Realtime replication for streamed tables.
--
-- The app subscribes to postgres_changes via `.stream()` in
-- SupabaseTransactionsRepository and SupabaseGoalsRepository. Realtime is
-- enabled at the service level (config.toml), but each table must ALSO belong to
-- the `supabase_realtime` publication (the "Database → Replication" toggle in
-- the dashboard). Without it the channel join is accepted and then immediately
-- rejected with a `system` error, the stream errors out, and the dashboard
-- shows "No pudimos cargar el panel."
--
-- Idempotent: safe to re-run. Add any future streamed table to the array below.

-- Ensure the publication exists (it does on hosted Supabase, but be safe).
do $$
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;
end $$;

-- Add each streamed table to the publication, skipping any already present.
do $$
declare t text;
begin
  foreach t in array array['transactions', 'goals'] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I;', t);
    end if;
  end loop;
end $$;
