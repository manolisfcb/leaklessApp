// Supabase Edge Function: budget-alert
//
// Invoked by a Database Webhook on INSERT into `public.transactions`. When a
// confirmed expense pushes its category's monthly budget past the configured
// alert threshold (or past 100%), it records the event in
// `budget_alert_events` (the unique constraint dedupes across devices/paths)
// and pushes an FCM notification to every household member's device EXCEPT the
// devices of whoever recorded the expense — that person already saw the in-app
// banner (budget_alert_watcher.dart).
//
// Request  (JSON, Supabase webhook shape):
//   { type: "INSERT", table: "transactions", schema: "public",
//     record: { id, household_id, category_id, type, status, occurred_at,
//               created_by, … }, old_record: null }
// Response (JSON): { skipped: string } | { fired: [{threshold, sent}] }
//
// Ops (see docs/BUDGET_ALERTS.md for the full runbook):
//   supabase secrets set FCM_SERVICE_ACCOUNT="$(cat service-account.json)"
//   supabase secrets set BUDGET_ALERT_WEBHOOK_SECRET=<random-string>
//   supabase functions deploy budget-alert --no-verify-jwt
//   Dashboard → Database → Webhooks: INSERT on public.transactions →
//     POST <functions-url>/budget-alert with header
//     x-webhook-secret: <same random string>

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
const OAUTH_TOKEN_URL = "https://oauth2.googleapis.com/token";

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

// ---------------------------------------------------------------------------
// FCM HTTP v1 auth: mint an OAuth2 access token from the service account.
// Cached at module scope — Edge Function isolates live long enough that this
// saves a round-trip on most invocations.
// ---------------------------------------------------------------------------

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

let cachedToken: { value: string; expiresAt: number } | null = null;

function base64UrlEncode(data: Uint8Array | string): string {
  const bytes = typeof data === "string"
    ? new TextEncoder().encode(data)
    : data;
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const body = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const der = Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
  return await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
}

async function getAccessToken(account: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.expiresAt - 60 > now) {
    return cachedToken.value;
  }

  const header = base64UrlEncode(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = base64UrlEncode(JSON.stringify({
    iss: account.client_email,
    scope: FCM_SCOPE,
    aud: OAUTH_TOKEN_URL,
    iat: now,
    exp: now + 3600,
  }));
  const key = await importPrivateKey(account.private_key);
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(`${header}.${claims}`),
  );
  const jwt = `${header}.${claims}.${base64UrlEncode(new Uint8Array(signature))}`;

  const res = await fetch(OAUTH_TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!res.ok) {
    throw new Error(`oauth_exchange_failed: ${res.status}`);
  }
  const data = await res.json();
  cachedToken = { value: data.access_token, expiresAt: now + data.expires_in };
  return cachedToken.value;
}

// ---------------------------------------------------------------------------
// FCM send. Returns "sent", "unregistered" (token must be deleted) or "error".
// ---------------------------------------------------------------------------

async function sendPush(
  account: ServiceAccount,
  accessToken: string,
  token: string,
  notification: { title: string; body: string },
  data: Record<string, string>,
): Promise<"sent" | "unregistered" | "error"> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({ message: { token, notification, data } }),
    },
  );
  if (res.ok) return "sent";

  // 404/UNREGISTERED = stale token (app uninstalled, token rotated): purge it.
  try {
    const body = await res.json();
    const details: { errorCode?: string }[] = body?.error?.details ?? [];
    if (
      res.status === 404 ||
      details.some((d) => d.errorCode === "UNREGISTERED")
    ) {
      return "unregistered";
    }
  } catch (_e) {
    // Fall through to generic error.
  }
  return "error";
}

// ---------------------------------------------------------------------------
// Webhook payload → alert pipeline
// ---------------------------------------------------------------------------

interface BudgetRow {
  id: string;
  household_id: string;
  category_id: string;
  amount_limit: number | string;
  spent: number | string;
  alert_enabled: boolean;
  alert_threshold_pct: number;
  period_start: string;
  categories: { name?: string } | null;
}

interface TransactionRecord {
  id?: string;
  household_id?: string;
  category_id?: string | null;
  type?: string;
  status?: string;
  occurred_at?: string;
  created_by?: string | null;
}

/// First day (UTC) of the month `occurred_at` falls in, as `yyyy-MM-dd`.
/// Matches `date_trunc('month', occurred_at)::date` used by
/// recompute_budget_spent — Supabase Postgres runs in UTC.
function periodStartOf(occurredAt: string): string | null {
  const d = new Date(occurredAt);
  if (Number.isNaN(d.getTime())) return null;
  const month = String(d.getUTCMonth() + 1).padStart(2, "0");
  return `${d.getUTCFullYear()}-${month}-01`;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  // Server-to-server auth: the webhook is configured to send this header. The
  // function is deployed with --no-verify-jwt, so this secret is the only gate.
  const secret = Deno.env.get("BUDGET_ALERT_WEBHOOK_SECRET");
  if (!secret) {
    return json({ error: "server_not_configured" }, 500);
  }
  if (req.headers.get("x-webhook-secret") !== secret) {
    return json({ error: "unauthorized" }, 401);
  }

  let payload: {
    type?: string;
    table?: string;
    record?: TransactionRecord;
  };
  try {
    payload = await req.json();
  } catch {
    return json({ error: "invalid_json" }, 400);
  }
  if (payload.type !== "INSERT" || payload.table !== "transactions") {
    return json({ skipped: "not_transaction_insert" });
  }

  const tx = payload.record ?? {};
  // Mirror recompute_budget_spent: only confirmed expenses count towards
  // `spent`, and a budget always has a category.
  if (tx.type !== "expense" || tx.status !== "confirmed") {
    return json({ skipped: "not_confirmed_expense" });
  }
  if (!tx.household_id || !tx.category_id || !tx.occurred_at) {
    return json({ skipped: "missing_fields" });
  }
  const periodStart = periodStartOf(tx.occurred_at);
  if (!periodStart) {
    return json({ skipped: "bad_occurred_at" });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  );

  // 1. The month's budget for this category. Its `spent` is already fresh:
  //    the AFTER trigger recompute_budget_spent_on_tx ran before the webhook
  //    delivered this event.
  const { data: budgetData, error: budgetError } = await supabase
    .from("budgets")
    .select(
      "id, household_id, category_id, amount_limit, spent, alert_enabled, " +
        "alert_threshold_pct, period_start, categories(name)",
    )
    .eq("household_id", tx.household_id)
    .eq("category_id", tx.category_id)
    .eq("period_start", periodStart)
    .maybeSingle();
  if (budgetError) {
    return json({ error: "budget_lookup_failed" }, 500);
  }
  const budget = budgetData as BudgetRow | null;
  if (!budget || !budget.alert_enabled) {
    return json({ skipped: "no_alerting_budget" });
  }
  const limit = Number(budget.amount_limit);
  const spent = Number(budget.spent);
  if (!(limit > 0)) {
    return json({ skipped: "zero_limit" });
  }
  const pctSpent = Math.floor((spent / limit) * 100);

  // 2. Record every threshold crossed this month exactly once. The unique
  //    constraint on (budget_id, period_start, threshold_pct) is the dedupe:
  //    ignoreDuplicates makes conflicting inserts return no rows, so a
  //    threshold that already fired (from any device or this function) is
  //    silently skipped.
  const thresholds = [...new Set([budget.alert_threshold_pct, 100])]
    .filter((t) => pctSpent >= t)
    .sort((a, b) => a - b);
  if (thresholds.length === 0) {
    return json({ skipped: "below_threshold" });
  }

  const { data: inserted, error: insertError } = await supabase
    .from("budget_alert_events")
    .upsert(
      thresholds.map((t) => ({
        household_id: budget.household_id,
        budget_id: budget.id,
        period_start: budget.period_start,
        threshold_pct: t,
      })),
      {
        onConflict: "budget_id,period_start,threshold_pct",
        ignoreDuplicates: true,
      },
    )
    .select("threshold_pct");
  if (insertError) {
    return json({ error: "event_insert_failed" }, 500);
  }
  const fired = (inserted ?? []).map((r) => r.threshold_pct as number);
  if (fired.length === 0) {
    return json({ skipped: "already_alerted" });
  }

  // 3. Devices of every household member except whoever recorded the expense
  //    (created_by NULL — legacy or service-role rows — notifies everyone).
  const { data: members, error: membersError } = await supabase
    .from("household_members")
    .select("user_id")
    .eq("household_id", budget.household_id);
  if (membersError) {
    return json({ error: "members_lookup_failed" }, 500);
  }
  const recipientIds = (members ?? [])
    .map((m) => m.user_id as string)
    .filter((id) => id !== tx.created_by);
  if (recipientIds.length === 0) {
    return json({ fired, sent: 0, skipped: "no_recipients" });
  }

  const { data: tokenRows, error: tokensError } = await supabase
    .from("device_push_tokens")
    .select("token")
    .in("user_id", recipientIds);
  if (tokensError) {
    return json({ error: "tokens_lookup_failed" }, 500);
  }
  const tokens = (tokenRows ?? []).map((r) => r.token as string);
  if (tokens.length === 0) {
    return json({ fired, sent: 0, skipped: "no_tokens" });
  }

  const accountRaw = Deno.env.get("FCM_SERVICE_ACCOUNT");
  if (!accountRaw) {
    return json({ error: "fcm_not_configured" }, 500);
  }
  let account: ServiceAccount;
  try {
    account = JSON.parse(accountRaw);
  } catch {
    return json({ error: "fcm_not_configured" }, 500);
  }

  // 4. One push per device for the MOST severe newly-fired threshold (if 80%
  //    and 100% fire on the same expense, one "limit reached" push beats two).
  const topThreshold = Math.max(...fired);
  const isLimit = topThreshold >= 100;
  const categoryName = budget.categories?.name ?? "";
  const notification = isLimit
    ? {
      title: "Límite de presupuesto alcanzado",
      body: categoryName.length > 0
        ? `El presupuesto de ${categoryName} llegó al 100% este mes.`
        : "Un presupuesto llegó al 100% este mes.",
    }
    : {
      title: "Alerta de presupuesto",
      body: categoryName.length > 0
        ? `Llevan ${pctSpent}% del presupuesto de ${categoryName} este mes.`
        : `Llevan ${pctSpent}% de un presupuesto este mes.`,
    };
  // notification_router.dart routes both types to /budgets.
  const data = {
    type: isLimit ? "limit_reached" : "budget_alert",
    budgetId: String(budget.id),
    categoryId: String(budget.category_id),
  };

  let accessToken: string;
  try {
    accessToken = await getAccessToken(account);
  } catch (_e) {
    return json({ error: "fcm_auth_failed" }, 502);
  }

  let sent = 0;
  const stale: string[] = [];
  const results = await Promise.all(
    tokens.map((t) => sendPush(account, accessToken, t, notification, data)),
  );
  results.forEach((result, i) => {
    if (result === "sent") sent += 1;
    if (result === "unregistered") stale.push(tokens[i]);
  });

  // 5. Purge tokens FCM reported as gone so we stop pushing at dead devices.
  if (stale.length > 0) {
    await supabase.from("device_push_tokens").delete().in("token", stale);
  }

  return json({ fired, sent, purged: stale.length });
});
