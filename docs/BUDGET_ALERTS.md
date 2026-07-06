# Budget alerts (push a la pareja)

When a confirmed expense pushes a category's monthly budget past its alert
threshold (or past 100%), the household's **other** members get an FCM push on
their phones; tapping it opens the Budgets screen. The person who recorded the
expense is excluded — they already get the in-app banner on their own device
(local path, `budget_alert_watcher.dart`).

> **Status: off until wired up.** The schema
> (`20260705120000_budget_alerts.sql`) and the client token registration
> (`push_token_registrar.dart`) ship with the app, but no push is sent until
> the Edge Function below is deployed and the Database Webhook is configured.

## How it works

```
INSERT into transactions
  ├─ DB trigger recompute_budget_spent_on_tx  → budgets.spent fresh
  └─ Database Webhook ──▶ Edge Function `budget-alert`
                              1. validate x-webhook-secret
                              2. load the month's budget (spent already fresh)
                              3. insert crossed thresholds into
                                 budget_alert_events (unique constraint =
                                 dedupe: only newly-fired thresholds notify)
                              4. FCM HTTP v1 push to household tokens minus
                                 created_by; purge UNREGISTERED tokens
```

- Dedupe is database-enforced: `budget_alert_events` is unique on
  `(budget_id, period_start, threshold_pct)`, and both the Edge Function and
  the in-app watcher insert with "ignore duplicates" and only notify when the
  insert returned a row. Each threshold alerts **once per month**, no matter
  how many devices or code paths race.
- The push `data` carries `type: budget_alert | limit_reached` plus
  `budgetId`/`categoryId`; `notification_router.dart` routes both types to
  `/budgets`.
- Device tokens live in `device_push_tokens`, written by the app
  (`push_token_registrar.dart`) on sign-in/refresh and deleted on sign-out.
  The function reads them with the service-role key and deletes any token FCM
  reports as `UNREGISTERED`.

## Turning it on

1. **Get the FCM service account key**: Firebase console → Project settings →
   Service accounts → *Generate new private key*. This JSON authorizes the
   FCM HTTP v1 API; it is a **server secret** — never ship it in the app or
   commit it.

2. **Store the secrets**:

   ```bash
   supabase secrets set FCM_SERVICE_ACCOUNT="$(cat service-account.json)"
   supabase secrets set BUDGET_ALERT_WEBHOOK_SECRET="$(openssl rand -hex 32)"
   ```

3. **Deploy the function** (no JWT check — the caller is the database, not a
   user; the shared secret is the gate):

   ```bash
   supabase functions deploy budget-alert --no-verify-jwt
   ```

   Source: `supabase/functions/budget-alert/index.ts`.

4. **Create the Database Webhook**: Dashboard → Database → Webhooks →
   *Create a new hook*:

   - Table: `public.transactions`, events: **INSERT** only.
   - Type: HTTP request, method POST, URL:
     `https://<project-ref>.supabase.co/functions/v1/budget-alert`.
   - HTTP header: `x-webhook-secret` = the same value stored in
     `BUDGET_ALERT_WEBHOOK_SECRET`.

## Testing

- Serve locally:

  ```bash
  supabase functions serve budget-alert --env-file supabase/.env.local
  ```

  then POST a synthetic webhook payload:

  ```bash
  curl -s localhost:54321/functions/v1/budget-alert \
    -H "Content-Type: application/json" \
    -H "x-webhook-secret: <secret>" \
    -d '{
      "type": "INSERT", "table": "transactions",
      "record": {
        "household_id": "<hh-uuid>", "category_id": "<cat-uuid>",
        "type": "expense", "status": "confirmed",
        "occurred_at": "2026-07-05T12:00:00Z", "created_by": "<user-uuid>"
      }
    }'
  ```

  The first call past a threshold returns `{"fired":[80],"sent":…}`; repeating
  it returns `{"skipped":"already_alerted"}` (the dedupe at work).

- On device: set a budget's threshold to 50%, record an expense that crosses
  it from partner A's phone → partner B's phone gets the push and tapping it
  opens `/budgets`; a second expense in the same month does **not** re-alert.

## Notes

- The push body is Spanish (app default); pushes are server-composed and do
  not follow the recipient's in-app locale yet.
- If several thresholds fire on one expense (e.g. 80% and 100% at once), all
  are recorded in `budget_alert_events` but only one push is sent, for the
  most severe (`limit_reached`).
- `transactions.created_by` is `NULL` on rows that predate the alerts
  migration or come from service-role jobs; those notify **all** members.
